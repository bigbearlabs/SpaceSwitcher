import Cocoa
import SpaceSwitcher


class ViewController: NSViewController {

  
  @IBOutlet weak var buttonsStackView: NSStackView!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()

    observeSpaceChangedNotifications()
    
    onSpaceChanged()
  }

  
  // MARK: - key operations
  
  @IBAction
  func switchToSpace(_ spaceButton: NSButton) {
    let windowNumberForSpace = spaceButton.cell!.representedObject as! Int
    self.spaceSwitcher.activateAnchorWindow(windowNumber: windowNumberForSpace)
  }

  
  func refreshWindowButtons() {
    self.removeAllWindowButtons()
    
    for window in self.spaceSwitcher.anchorWindows {
      self.addButton(forWindowNumber: window.windowNumber)
    }
  }

  // MARK: - internals
  
  func addButton(forWindowNumber windowNumber: Int) {
    let button = NSButton(
      title: String(windowNumber),
      target: self,
      action: #selector(switchToSpace(_:)))
    button.cell!.representedObject = windowNumber

    buttonsStackView.addView(button, in: .top)
  }
  
  func removeAllWindowButtons() {
    for button in buttonsStackView.views(in: .top) {
      buttonsStackView.removeView(button)
    }
  }
  
  
  var spaceSwitcher: SpaceSwitcher {
    return (NSApp.delegate as! AppDelegate).spaceSwitcher!
  }
  
}


// MARK: - responding to events

extension ViewController: SpaceChangeObserver {
  
  func onSpaceChanged() {
    
    // ensure we handle the event after SpaceSwitcher.
    DispatchQueue.main.async {

      self.refreshWindowButtons()
    }
    
  }
  
}
