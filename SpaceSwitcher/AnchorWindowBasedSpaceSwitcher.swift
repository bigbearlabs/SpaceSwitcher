import AppKit

import BBLSpaces




public class AnchorWindowBasedSpaceSwitcher: NSObject, SpaceSwitcher {
  
  
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
  
  
  // MARK: -
  
  public func switchToSpace(token: SpaceToken) {
    self.activateAnchorWindow(forSpaceToken: token)
    
    ensureNoMultipleAnchorWindowsInSpace {
      
    }
  }
  
  // MARK: -
  
  func newAnchorWindowController() -> NSWindowController {
//    return SpaceAnchorWindow()
    let identifier = self.isCurrentSpaceFullScreen ?
      "FullScreenAnchorWindowController"
      : "AnchorWindowController"
    let controller = storyboard.instantiateController(withIdentifier: identifier) as! NSWindowController
    return controller
  }

  lazy var storyboard: NSStoryboard = {
    return NSStoryboard(name: "AnchorWindows", bundle: Bundle(for: type(of: self)))
  }()
  
  var isCurrentSpaceFullScreen: Bool {
//    return false // STUB
    
    return SpacesBroker().isCurrentSpaceInFullScreenMode()
  }
  
//  @discardableResult
  func placeAnchorWindow() {
    
    defer {
      ensureNoMultipleAnchorWindowsInSpace() {}
    }
    
    let anchorWindowController = newAnchorWindowController()

    anchorWindowController.window?.setIsVisible(true)
    guard anchorWindowController.window?.isOnActiveSpace == true else {
      
      // something will prevent this window from activating in the current space.
      // this is probably the dashboard space, or a full-screen space where
      // other app windows cannot legally show up.
      
      // just give up placing an anchor window.

//      return nil
      return
    }
    
    // finalise the anchor state.
//    anchorWindowController.window?.setIsVisible(true)

    self.anchorWindowControllers.append(anchorWindowController)

//    return anchorWindow
  }
  
  
  public func activateAnchorWindow(forSpaceToken: SpaceToken) {
    
    guard let anchorWindowController =
      self.anchorWindowControllers
      .filter({ $0.window!.windowNumber == forSpaceToken })
      .first
    else {
      fatalError("could not find anchor window \(forSpaceToken) to activate; please file a bug.")
    }
    
    guard anchorWindowController.window != anchorWindowForCurrentSpace else {
      // anchor window is already in current space.
      return
    }

//    if anchorWindowController is AppActivatingWindowController {
//      anchorWindowController.window?.makeKeyAndOrderFront(self)
//    } else {
      anchorWindowController.window?.activateToSwitchSpace()
    
//    }
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

//      self.anchorWindowControllers = self.anchorWindowControllers.filter {
//        $0.window != nil
//         && !obsoleteAnchorWindows.contains($0.window!)
//      }
//
//      for window in obsoleteAnchorWindows {
//        window.close()
//      }
      
      return
    }
    
    completionHandler()
//    }
  }
  
  
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
}


extension AnchorWindowBasedSpaceSwitcher: SpaceChangeObserver {
  
  /// place an anchor whenever it is found that no anchor window exists for the current space.
  public func onSpaceChanged() {
    
    // appears we need some breathing room before isOnActiveSpace is reported properly over all windows.
//    DispatchQueue.main.async {
    self.ensureNoMultipleAnchorWindowsInSpace() {
    
      if self.anchorWindowForCurrentSpace == nil {
        
        // drop an anchor.
        self.placeAnchorWindow()
      }
    
      self.ensureNoMultipleAnchorWindowsInSpace() {
    
      if let currentSpaceToken = self.spaceTokenForCurrentSpace {
        self.changeHandler(currentSpaceToken)
      }
//    }
      }
    }
  }
  
}


class SpaceAnchorWindow: NSPanel {
  
  convenience init() {
    self.init(
      contentRect: CGRect(x: 0, y: 0, width: 5, height: 5),
      styleMask: [.borderless, .utilityWindow],
      backing: .buffered,
      defer: false)
    
    // ensure windows are released when no longer referenced.
    self.isReleasedWhenClosed = true

    // make anchor window transparent.
    self.transparent = true
    
    // exclude anchor window from window behaviour that might get in the way.
    self.collectionBehavior = [.ignoresCycle, .stationary]

  }
  

  
  // override framework methods to work around cocoa assumptions of a transparent window's
  // behaviour.
  
  override var canBecomeKey: Bool {
    return true
  }
  
  override var canBecomeMain: Bool {
    return true
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
          $0 is SpaceAnchorWindow == false
            && $0.isVisible
        },
        self.collectionBehavior
    )

    // the window must be set to the expose-recognised collection behaviour in order to fling the space.
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
