import Cocoa
import SpaceSwitcher



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var spaceSwitcher: SpaceSwitcher?

  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    // SpaceSwitcher will obtain a space token every time the app discovers a new space.
    // the info is used by ViewController to add a button that will switch to each discovered
    // space.
    spaceSwitcher = SpaceSwitcher(changeHandler: { currentSpaceToken in
      if let currentSpaceToken = currentSpaceToken,
        currentSpaceToken != self.currentSpaceToken {
        self.previousSpaceToken = self.currentSpaceToken
        self.currentSpaceToken = currentSpaceToken
      }
    })
  }

  
  // MARK: - 'switch to previous' app
    
  var currentSpaceToken: Int?
  var previousSpaceToken: Int?
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



extension AppDelegate {
  
  @IBAction
  func switchToPreviousSpace(_ sender: Any) {
    if let spaceToken = self.previousSpaceToken {
      spaceSwitcher?.activateAnchorWindow(forSpaceToken: spaceToken)
    }
  }
}
