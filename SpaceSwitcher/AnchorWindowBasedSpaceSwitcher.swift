import AppKit



protocol AnchorWindowOrchestrator: AnyObject {
  var anchorWindowControllersBySpaceToken: [SpaceToken : NSWindowController] { get set }
  
  func anchorWindowController(spaceToken: SpaceToken) -> NSWindowController?
}

extension AnchorWindowOrchestrator {
  
  var anchorWindowForActiveSpace: NSWindow? {
    
    //    ensureNoMultipleAnchorWindowsInSpace() {
    
    let anchorWindowsOnSpace = self.anchorWindowControllersBySpaceToken.map { $0.value.window! }
      .filter {
        $0.isOnMainScreenActiveSpace
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

    guard anchorWindowController.window != anchorWindowForActiveSpace else {
      // anchor window is already in current space.
      return
    }
    
    anchorWindowController.window?.activateToSwitchSpace()
  }
  
  
  func ensureSingeAnchorWindowInActiveSpace(completionHandler: @escaping () -> Void) {
    
    // when > 1 anchor window found in space,
    let anchorWindowsInSpace = self.anchorWindowControllersBySpaceToken.values
      .filter {
        $0.window?.isOnMainScreenActiveSpace == true
      }
      .map { $0.window! }
    
    guard anchorWindowsInSpace.count <= 1 else {
      
      // remove all but the first one.
      let obsoleteAnchorWindows = anchorWindowsInSpace.dropFirst()
      
      print("will remove obsolete windows \(obsoleteAnchorWindows) ")
      
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
  
  let spaceChangeHandler: (SpaceToken?) -> ()


  var spacesPrivateApiTool: SpacesPrivateApiTool?
    = SpacesPrivateApiTool()
  
  public init(changeHandler: @escaping (SpaceToken?) -> () = {_ in }) {
    self.spaceChangeHandler = changeHandler
    
    super.init()
    
    if let placement = self.spacesPrivateApiTool?.placeAnchorWindowsInAllSpaces() {
      self.anchorWindowControllersBySpaceToken = placement
    }
    
    observeSpaceChangedNotifications()
    
    onSpaceChanged()
  }
  
  fileprivate func removeAnchor(spaceToken: SpaceToken) {
    if let window = self.anchorWindowControllersBySpaceToken[spaceToken] {
      print("closing and removing anchor window \(window) for \(spaceToken)")
      window.close()
    }
    self.anchorWindowControllersBySpaceToken.removeValue(forKey: spaceToken)
  }
  

  // MARK: -
  
  public var stateTuple: (
    spacesByDisplay: [DisplayId : [SpaceToken]],
    currentSpaces: [SpaceToken],
    activeSpace: SpaceToken) {
    let info = spacesPrivateApiTool!.spacesBroker.spacesInfo
    
    let ts = info.screens.map {
      ($0.displayId, $0.spaceIds.map { $0.intValue })
    }
    let states = Dictionary(uniqueKeysWithValues: ts)

    return (
      spacesByDisplay: states,
      currentSpaces: info.currentSpaceIds.map { $0.intValue },
      activeSpace: info.activeSpaceId
    )
  }
  
  public var spaceTokenForActiveSpace: SpaceToken? {
    return anchorWindowControllersBySpaceToken.first { $0.value.window ===  self.anchorWindowForActiveSpace }?.key
  }
  
  func anchorWindowController(spaceToken: SpaceToken) -> NSWindowController? {
    return self.anchorWindowControllersBySpaceToken[spaceToken]
  }
  

  // MARK: -
  
  public func switchToSpace(token: SpaceToken) {
    self.activateAnchorWindow(forSpaceToken: token)
    
    ensureSingeAnchorWindowInActiveSpace {}
  }
  
  
  // MARK: -
  
  func placeAnchorWindowInActiveSpace() {
    
    defer {
      ensureSingeAnchorWindowInActiveSpace() {}
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

    let spaceToken =
      self.spacesPrivateApiTool?.activeSpaceId
      // default to using the anchor window's window number.
      ?? anchorWindowController.window!.windowNumber
        
    self.anchorWindowControllersBySpaceToken[spaceToken] = anchorWindowController
    
  }
  
  
  // MARK: -
  
}

extension AnchorWindowBasedSpaceSwitcher: SpaceChangeObserver {
  
  
  /// place an anchor whenever no anchor window exists for the active space.
  /// remove anchors for space ids that no longer exist.
  public func onSpaceChanged() {
    
    // remove anchors for spaces that don't exist any more.
    if let spaceIds = spacesPrivateApiTool?.spaceIds {
      let removedSpaceIds = Set(self.anchorWindowControllersBySpaceToken.keys).subtracting(spaceIds)
      for id in removedSpaceIds {
        self.removeAnchor(spaceToken: id)
      }
    }
    
    // appears we need some breathing room before isOnActiveSpace is reported properly over all windows.
    self.ensureSingeAnchorWindowInActiveSpace() {
    
      if self.anchorWindowForActiveSpace == nil {
        
        // drop an anchor.
        self.placeAnchorWindowInActiveSpace()
      }
    
      self.ensureSingeAnchorWindowInActiveSpace() {
    
        let activeSpaceToken = self.spaceTokenForActiveSpace!
        self.spaceChangeHandler(activeSpaceToken)
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




extension NSWindow {
  var isOnMainScreenActiveSpace: Bool {
    return self.isOnActiveSpace
      && self.screen == NSScreen.main
  }
}
