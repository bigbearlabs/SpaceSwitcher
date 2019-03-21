import Cocoa



extension NSWindow {
  
  @IBInspectable
  var transparent: Bool {
    get {
      return
        !self.isOpaque
          && self.backgroundColor == NSColor.clear
    }
    set {
      self.isOpaque = !newValue
      self.backgroundColor = newValue ? NSColor.clear : self.backgroundColor
    }
  }
  
}
