import AppKit



protocol AnchorWindowOrchestrator: AnyObject {
  var anchorWindowControllersBySpaceToken: [SpaceToken : NSWindowController] { get set }
  
  func anchorWindowController(spaceToken: SpaceToken) -> NSWindowController?
}

extension AnchorWindowOrchestrator {
  
  var anchorWindowForCurrentSpace: NSWindow? {
    
    //    ensureNoMultipleAnchorWindowsInSpace() {
    
    let anchorWindowsOnSpace = self.anchorWindowControllersBySpaceToken.map { $0.value.window! }.filter {
      $0.isVisible && $0.isOnActiveSpace
    }
    //
    //    assert(anchorWindowsOnSpace.count <= 1,
    //           "multiple anchor windows found in space; please file a bug.")
    
    return anchorWindowsOnSpace.first
    //  }
    
  }

  func activateAnchorWindow(forSpaceToken: SpaceToken) {
    
    guard let anchorWindowController = self.anchorWindowController(spaceToken: forSpaceToken)
      else {
        fatalError("could not find anchor window \(forSpaceToken) to activate; please file a bug.")
    }

    guard anchorWindowController.window != anchorWindowForCurrentSpace else {
      // anchor window is already in current space.
      return
    }
    
    anchorWindowController.window?.activateToSwitchSpace()
  }
  
  
  func ensureNoMultipleAnchorWindowsInSpace(completionHandler: @escaping () -> Void) {
    let anchorWindows = self.anchorWindowControllersBySpaceToken.map { $0.value.window!}
    
    // when > 1 anchor window found in space,
    let anchorWindowsInSpace = anchorWindows.filter {
      $0.isVisible && $0.isOnActiveSpace
    }
    
    guard anchorWindowsInSpace.count <= 1 else {
      
      // remove all but the first one.
      let obsoleteAnchorWindows = anchorWindowsInSpace.dropFirst()
      
      self.anchorWindowControllersBySpaceToken = self.anchorWindowControllersBySpaceToken.filter {
        $0.value.window != nil
          && !obsoleteAnchorWindows.contains($0.value.window!)
      }
      
      for window in obsoleteAnchorWindows {
        window.close()
      }
      
      return
    }
    
    completionHandler()
  }
  
}


// MARK: -

public class AnchorWindowBasedSpaceSwitcher: NSObject, SpaceSwitcher, AnchorWindowOrchestrator {
  
  var anchorWindowControllersBySpaceToken: [SpaceToken : NSWindowController] = [:]
  
  let changeHandler: (SpaceToken?) -> ()


  var spacesPrivateApiTool: SpacesPrivateApiTool?
    = SpacesPrivateApiTool()
  
  public init(changeHandler: @escaping (SpaceToken?) -> () = {_ in }) {
    self.changeHandler = changeHandler
    
    super.init()
    
    if let placement = self.spacesPrivateApiTool?.placeAnchorWindowsInAllSpaces() {
      self.anchorWindowControllersBySpaceToken = placement
    }
    
    observeSpaceChangedNotifications()
    
    onSpaceChanged()
  }
  
  
  // MARK: -
  
  public var spaceTokens: [SpaceToken] {
    return self.spacesPrivateApiTool?.spaceIds
      ?? Array(self.anchorWindowControllersBySpaceToken.keys)
  }
  
  public var spaceTokenForCurrentSpace: SpaceToken? {
    return anchorWindowControllersBySpaceToken.first { $0.value ===  self.anchorWindowForCurrentSpace }?.key
  }
  
  public func spaceTokenForCurrentSpace(currentAnchorController: NSWindowController) -> SpaceToken {
    // if private api available, return space id.
    // all anchors must have been placed prior.
    return spacesPrivateApiTool?.currentSpaceId
      ?? currentAnchorController.window!.windowNumber
  }
  
  func anchorWindowController(spaceToken: SpaceToken) -> NSWindowController? {
    return self.anchorWindowControllersBySpaceToken[spaceToken]
  }
  

  // MARK: -
  
  public func switchToSpace(token: SpaceToken) {
    self.activateAnchorWindow(forSpaceToken: token)
    
    ensureNoMultipleAnchorWindowsInSpace {}
  }
  
  
  // MARK: -
  
  func placeAnchorWindowInCurrentSpace() {
    
    defer {
      ensureNoMultipleAnchorWindowsInSpace() {}
    }
    
    let anchorWindowController = anchorWindowVendor.newAnchorWindowController()

    setup(anchorWindowController: anchorWindowController)
    
    // for full screen mode + multiple monitors, by default the window will land in the non-full-screen space.
    // mitigate by updating frame to a region of the main screen.
    if let mainScreen = NSScreen.main {
      let origin = mainScreen.frame.origin
      anchorWindowController.window?.setFrameOrigin(origin)
    }

    guard anchorWindowController.window?.isOnActiveSpace == true else {
      
      // something will prevent this window from activating in the current space.
      // this is probably the dashboard space, or a full-screen space where
      // other app windows cannot legally show up.
      
      // just give up placing an anchor window.

      return
    }

    let spaceToken = self.spaceTokenForCurrentSpace(currentAnchorController: anchorWindowController)
    self.anchorWindowControllersBySpaceToken[spaceToken] = anchorWindowController
    
  }
  
  
  // MARK: -
  
}

extension AnchorWindowBasedSpaceSwitcher: SpaceChangeObserver {
  
  /// place an anchor whenever it is found that no anchor window exists for the current space.
  public func onSpaceChanged() {
    
    // appears we need some breathing room before isOnActiveSpace is reported properly over all windows.
    self.ensureNoMultipleAnchorWindowsInSpace() {
    
      if self.anchorWindowForCurrentSpace == nil {
        
        // drop an anchor.
        self.placeAnchorWindowInCurrentSpace()
      }
    
      self.ensureNoMultipleAnchorWindowsInSpace() {
    
        if let currentSpaceToken = self.spaceTokenForCurrentSpace {
          self.changeHandler(currentSpaceToken)
        }
      }
    }
  }
  
}


extension NSWindow {
  
  // NOTE a case where this falls apart:
  // activating to
  func activateToSwitchSpace() {
    
    // the app be active in order for window to fling the space.
    NSApp.activate(ignoringOtherApps: true)

    // grab some state prior to the voodoo magic, in order to restore them afterwards.
    let collectionBehaviour = self.collectionBehavior

    // the window must be set to a specific collection behaviour in order to fling the space.
    self.collectionBehavior = [.ignoresCycle]

    self.makeKeyAndOrderFront(self)

    DispatchQueue.main.async {
      self.collectionBehavior = collectionBehaviour
    }
  }
  
}


