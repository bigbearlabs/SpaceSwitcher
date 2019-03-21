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
    let spaceToken = spaceButton.cell!.representedObject as! Int
    
    self.spaceSwitcher.switchToSpace(token: spaceToken)
  }

  
  func refreshSwitchToSpaceButtons() {
    self.removeAllSwitchToSpaceButtons()
    
    let currentSpaceToken = self.spaceSwitcher.spaceTokenForCurrentSpace
    for token in self.spaceSwitcher.spaceTokens {
      let isCurrent = (token == currentSpaceToken)
      self.addButton(forSpaceToken: token, markAsCurrent: isCurrent)
    }
  }

  
  // MARK: - internals
  
  func addButton(forSpaceToken spaceToken: Int, markAsCurrent: Bool = false) {
    var title = String(spaceToken)
    if markAsCurrent {
      title = "\(title) *"
    }
    let button = NSButton(
      title: title,
      target: self,
      action: #selector(switchToSpace(_:)))
    button.cell!.representedObject = spaceToken

    buttonsStackView.addView(button, in: .top)
  }
  
  func removeAllSwitchToSpaceButtons() {
    for button in buttonsStackView.views(in: .top) where button is NSButton {
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

      self.refreshSwitchToSpaceButtons()
      
      for window in NSApp.windows {
        window.setIsVisible(true)
      }
    }
    
  }
  
}


class FullScreenAnchorViewController: NSViewController {
  

  @IBAction func action_hideWindow(_ sender: Any) {
    self.view.window?.orderOut(self)
  }
  
}
