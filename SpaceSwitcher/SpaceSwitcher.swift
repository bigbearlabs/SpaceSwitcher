import AppKit



extension SpaceSwitcher: SpaceChangeObserver {
  
  /// place an anchor whenever it is found that no anchor window exists for the current space.
  public func onSpaceChanged() {
    
    ensureNoMultipleAnchorWindowsInSpace()
    
    defer {
      ensureNoMultipleAnchorWindowsInSpace()
    }
    
    if self.anchorWindowForCurrentSpace == nil {
      
      // drop an anchor.
      placeAnchorWindow()
    }
    
  }
  
}



public class SpaceSwitcher: NSObject {
  
  
  public var spaceTokens: [Int] {
    return anchorWindows.map { $0.windowNumber }
  }

  
  var anchorWindows: [SpaceAnchorWindow] = []
  
  var anchorWindowForCurrentSpace: SpaceAnchorWindow? {
    
    ensureNoMultipleAnchorWindowsInSpace()
    
    let anchorWindowsOnSpace = anchorWindows.filter {
        $0.isOnActiveSpace
    }
    
    assert(anchorWindowsOnSpace.count <= 1,
           "multiple anchor windows found in space; please file a bug.")
    
    return anchorWindowsOnSpace.first
  }
  
  
  override public init() {
    super.init()
    
    observeSpaceChangedNotifications()
    
    onSpaceChanged()
  }
  
  
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
  
  
  public func activateAnchorWindow(forSpaceToken: Int) {
    
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

    // make anchor windows transparent.
    // TODO
    
    // exclude anchor window from window behaviour that might get in the way.
    // NOTE tried adding .transient or .stationary in an attempt to hide the window from Expose.
    // this resulted in loss of space flinging when window was activated.
    // we work around the expose-related noise by making the very small and transparent.
    self.collectionBehavior = [.ignoresCycle]

  }
  
  func activateToSwitchSpace() {

    self.makeKeyAndOrderFront(self)

    // need to hide this app in order not to disturb the system-default
    // app activation behaviour when switching spaces.
    NSApp.hide(self)
    
    // if this app needs to activate after the switch, implement by calling #orderFront
    // on the appropriate window(s) in a space change notification handler.
  }
  
  
  // override framewokr methods to work around cocoa assumptions of a transparent window's
  // behaviour.
  
  override var canBecomeKey: Bool {
    return true
  }
  
  override var canBecomeMain: Bool {
    return true
  }

}
