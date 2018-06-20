import Cocoa
import SpaceSwitcher


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var spaceSwitcher: SpaceSwitcher?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    spaceSwitcher = SpaceSwitcher()
    
    observeSpaceChangedNotifications()
  }

  
}

extension AppDelegate: SpaceChangeObserver {
  
  func onSpaceChanged() {
    DispatchQueue.main.async {
      // switching the space using a SpaceSwitcher entails hiding this app. make the main demo window visible again.
      if let window = NSApp.windows.filter( {
        $0 is SpaceAnchorWindow == false
          && $0.isOnActiveSpace
      })
      .first {
        
        window.orderFront(self)
      }

    }
  }
  
}
