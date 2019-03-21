/// an opaque identifier for a space.
/// not to be confused with other types of space ids already used by the system.
public typealias SpaceToken = Int


public protocol SpaceSwitcher {
  
  var spaceTokenForCurrentSpace: SpaceToken? { get }
  
  var spaceTokens: [SpaceToken] { get }
  
  func switchToSpace(token: SpaceToken)
}


class AppActivatingWindowController: NSWindowController, NSWindowDelegate {
  
  func windowDidBecomeKey(_ notification: Notification) {
//    NSApp.activate(ignoringOtherApps: true)
  }
  
}
