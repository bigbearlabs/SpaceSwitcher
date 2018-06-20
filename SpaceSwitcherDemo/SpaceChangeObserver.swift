import Cocoa


protocol SpaceChangeObserver {
  
  func observeSpaceChangedNotifications()
  
  func onSpaceChanged()
}


extension SpaceChangeObserver where Self: AnyObject {
  
  func observeSpaceChangedNotifications() {
    
    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil,
      queue: nil)
    { [unowned self] notification in
      
      self.onSpaceChanged()
    }
  }
  
}
