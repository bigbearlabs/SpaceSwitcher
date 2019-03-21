import AppKit


protocol AnchorWindowOrchestrator: AnyObject {
  var anchorWindowControllers: [NSWindowController] { get set }
  
  func anchorWindowController(spaceToken: SpaceToken) -> NSWindowController?
}

extension AnchorWindowOrchestrator {
  
  var anchorWindowForCurrentSpace: NSWindow? {
    
    //    ensureNoMultipleAnchorWindowsInSpace() {
    
    let anchorWindowsOnSpace = self.anchorWindowControllers.map { $0.window! }.filter {
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
    //    DispatchQueue.main.async {
    let anchorWindows = self.anchorWindowControllers.map { $0.window!}
    
    // when > 1 anchor window found in space,
    let anchorWindowsInSpace = anchorWindows.filter {
      $0.isVisible && $0.isOnActiveSpace
    }
    
    guard anchorWindowsInSpace.count <= 1 else {
      
      // remove all but the first one.
      let obsoleteAnchorWindows = anchorWindowsInSpace.dropFirst()
      
      self.anchorWindowControllers = self.anchorWindowControllers.filter {
        $0.window != nil
          && !obsoleteAnchorWindows.contains($0.window!)
      }
      
      for window in obsoleteAnchorWindows {
        window.close()
      }
      
      return
    }
    
    completionHandler()
    //    }
  }
  

}
public class AnchorWindowBasedSpaceSwitcher: NSObject, SpaceSwitcher, AnchorWindowOrchestrator {
  
  
  public var spaceTokens: [SpaceToken] {
    return self.anchorWindowControllers.map { $0.window!.windowNumber }
  }
  
  public var spaceTokenForCurrentSpace: SpaceToken? {
    return anchorWindowForCurrentSpace?.windowNumber
  }

  
  var anchorWindowControllers: [NSWindowController] = []
  

  let changeHandler: (SpaceToken?) -> ()
  
  
  public init(changeHandler: @escaping (SpaceToken?) -> () = {_ in }) {
    self.changeHandler = changeHandler
    super.init()
    
    observeSpaceChangedNotifications()
    
    onSpaceChanged()
  }
  
  func anchorWindowController(spaceToken: SpaceToken) -> NSWindowController? {
    let o = self.anchorWindowControllers
      .first(where: { $0.window!.windowNumber == spaceToken })
    return o
  }
  
  
  // MARK: -
  
  public func switchToSpace(token: SpaceToken) {
    self.activateAnchorWindow(forSpaceToken: token)
    
    ensureNoMultipleAnchorWindowsInSpace {
      
    }
  }
  
  // MARK: -
  
  
  func placeAnchorWindow() {
    
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

//      return nil
      return
    }

    self.anchorWindowControllers.append(anchorWindowController)
  }
  
}


extension AnchorWindowBasedSpaceSwitcher: SpaceChangeObserver {
  
  /// place an anchor whenever it is found that no anchor window exists for the current space.
  public func onSpaceChanged() {
    
    // appears we need some breathing room before isOnActiveSpace is reported properly over all windows.
    self.ensureNoMultipleAnchorWindowsInSpace() {
    
      if self.anchorWindowForCurrentSpace == nil {
        
        // drop an anchor.
        self.placeAnchorWindow()
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
    let (
      windowsVisiblePriorToSwitch,
      collectionBehaviour
      ) = (
        NSApp.windows.filter {
          $0.isVisible
        },
        self.collectionBehavior
    )

    // the window must be set to a specific collection behaviour in order to fling the space.
    self.collectionBehavior = [.ignoresCycle]

    self.makeKeyAndOrderFront(self)

    DispatchQueue.main.async {
      self.collectionBehavior = collectionBehaviour

      // need to hide this app in order not to disturb the system-default
      // app activation behaviour when switching spaces.
      
  //    NSApp.hide(self)
      
        // temp disable.
  //    NSApp.deactivate()

      // a delay is needed so spaces transition completes before the following logic.
      // this will probably break (in a minor way) on slower systems or when the window server is sluggish.
      let smallDelay = 0.5
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + smallDelay) {


        // restore window states prior to the app activation and hiding.

  //        for window in windowsVisiblePriorToSwitch {
  //          window.setIsVisible(true)
  //        }


        // TODO unhide the app.
  //      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
  //        NSApp.unhide(self)
  //      }
        
  //      NSApp.deactivate()
      }
    }
  }
  
}
