import Cocoa
import SpaceSwitcher



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var spaceSwitcher: SpaceSwitcher!

  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    // SpaceSwitcher will obtain a space token every time the app discovers a new space.
    // the info is used by ViewController to add a button that will switch to each discovered
    // space.
//    spaceSwitcher = AnchorWindowBasedSpaceSwitcher()
    spaceSwitcher = CGPrivateAPIBasedSpaceSwitcher()
  }

}



class DemoPanel: NSPanel {
  
  // forbid the panel to take focus, to rule out accidentally lucky spaces switches when it comes in focus.
  
  override var canBecomeMain: Bool {
    return false
  }
  override var canBecomeKey: Bool {
    return false
  }
}

