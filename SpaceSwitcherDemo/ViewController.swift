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
    self.spaceSwitcher.activateAnchorWindow(forSpaceToken: spaceToken)
  }

  
  func refreshSwitchToSpaceButtons() {
    self.removeAllSwitchToSpaceButtons()
    
    for token in self.spaceSwitcher.spaceTokens {
      self.addButton(forSpaceToken: token)
    }
  }

  
  // MARK: - internals
  
  func addButton(forSpaceToken spaceToken: Int) {
    let button = NSButton(
      title: String(spaceToken),
      target: self,
      action: #selector(switchToSpace(_:)))
    button.cell!.representedObject = spaceToken

    buttonsStackView.addView(button, in: .top)
  }
  
  func removeAllSwitchToSpaceButtons() {
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

      self.refreshSwitchToSpaceButtons()
    }
    
  }
  
}
