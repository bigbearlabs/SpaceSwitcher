import AppKit



public class AnchorWindowBasedSpaceSwitcher: NSObject, SpaceSwitcher {
  
  
  public var spaceTokens: [SpaceToken] {
    return anchorWindows.map { $0.windowNumber }
  }
  
  public var spaceTokenForCurrentSpace: SpaceToken? {
    return anchorWindowForCurrentSpace?.windowNumber
  }

  
  var anchorWindows: [SpaceAnchorWindow] = []
  

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
  }
  
  // MARK: -
  
  @discardableResult
  func placeAnchorWindow() -> SpaceAnchorWindow? {
    
    defer {
      ensureNoMultipleAnchorWindowsInSpace()
    }
    
    let anchorWindow = SpaceAnchorWindow()
    
    guard anchorWindow.isOnActiveSpace else {
      
      // something will prevent this window from activating in the current space.
      // this is probably the dashboard space, or a full-screen space where
      // other app windows cannot legally show up.
      
      // just give up placing an anchor window.

      return nil
    }
    
    // finalise the anchor state.
    anchorWindow.setIsVisible(true)

    self.anchorWindows.append(anchorWindow)

    return anchorWindow
  }
  
  
  public func activateAnchorWindow(forSpaceToken: SpaceToken) {
    
    guard let anchorWindow =
      self.anchorWindows
      .filter({ $0.windowNumber == forSpaceToken })
      .first
    else {
      fatalError("could not find anchor window \(forSpaceToken) to activate; please file a bug.")
    }
    
    guard anchorWindow != anchorWindowForCurrentSpace else {
      // anchor window is already in current space.
      return
    }

    anchorWindow.activateToSwitchSpace()

  }
  
  
  func ensureNoMultipleAnchorWindowsInSpace() {
    
    // when > 1 anchor window found in space,
    let anchorWindowsInSpace = self.anchorWindows.filter {
      $0.isOnActiveSpace
    }
    
    guard anchorWindowsInSpace.count <= 1 else {
      
      // remove all but the first one.
      let obsoleteAnchorWindows = anchorWindowsInSpace.dropFirst()
      for window in obsoleteAnchorWindows {

        if let i = anchorWindows.index(of: window) {
          anchorWindows.remove(at: i)
        } else {
          // obsolete anchor window not found in our list of anchor windows?
          // invalid situation.
          fatalError()
        }
      }
      
      return
    }
    
  }
  
  
  var anchorWindowForCurrentSpace: SpaceAnchorWindow? {
    
    ensureNoMultipleAnchorWindowsInSpace()
    
    let anchorWindowsOnSpace = anchorWindows.filter {
      $0.isOnActiveSpace
    }
    
    assert(anchorWindowsOnSpace.count <= 1,
           "multiple anchor windows found in space; please file a bug.")
    
    return anchorWindowsOnSpace.first
  }
  
  
}


extension AnchorWindowBasedSpaceSwitcher: SpaceChangeObserver {
  
  /// place an anchor whenever it is found that no anchor window exists for the current space.
  public func onSpaceChanged() {
    
    ensureNoMultipleAnchorWindowsInSpace()
    
    if self.anchorWindowForCurrentSpace == nil {
      
      // drop an anchor.
      placeAnchorWindow()
    }
    
    ensureNoMultipleAnchorWindowsInSpace()
    
    if let currentSpaceToken = self.spaceTokenForCurrentSpace {
      self.changeHandler(currentSpaceToken)
    }
    
    
  }
  
}


class SpaceAnchorWindow: NSWindow {
  
  convenience init() {
    self.init(
      contentRect: CGRect(x: 0, y: 0, width: 5, height: 5),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false)
    
    // ensure windows are released when no longer referenced.
    self.isReleasedWhenClosed = true

    // make anchor window transparent.
    self.transparent = true
    
    // exclude anchor window from window behaviour that might get in the way.
    self.collectionBehavior = [.ignoresCycle, .stationary]

  }
  
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

    DispatchQueue.main.async {
      
      self.makeKeyAndOrderFront(self)

      // need to hide this app in order not to disturb the system-default
      // app activation behaviour when switching spaces.
      NSApp.hide(self)
      
      // restore window states prior to the app activation and hiding.
      // a delay is needed before which spaces transition should complete in order for this approach to work.
      // this will probably break (in a minor way) on slower systems or when the window server is sluggish.
      let smallDelay = 0.5
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + smallDelay) {
        
        for window in windowsVisiblePriorToSwitch {
          window.setIsVisible(true)
        }
        
        self.collectionBehavior = collectionBehaviour
      }
    
    }
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
