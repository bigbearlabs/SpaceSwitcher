import Cocoa



let anchorWindowVendor = AnchorWindowVendor()

class AnchorWindowVendor {
  
  func newAnchorWindowController() -> NSWindowController {
    let identifier = "AnchorWindowController"
    let controller = storyboard.instantiateController(withIdentifier: identifier) as! NSWindowController
    
    return controller
  }
  
  let storyboard = NSStoryboard(name: "AnchorWindows", bundle: Bundle(for: AnchorWindowVendor.self))
}



func setup(anchorWindowController: NSWindowController) {
//  anchorWindowController.window?.transparent = true
  anchorWindowController.window?.setIsVisible(true)
}
