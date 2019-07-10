import Cocoa
import SpaceSwitcher


class ViewController: NSViewController {


  var activeSpaceToken: SpaceToken? {
    didSet {
      self.previousSpaceToken = oldValue
      
      
      self.refreshSwitchToSpaceButtons()
      
      for window in NSApp.windows {
        window.setIsVisible(true)
      }
    }
  }
  
  var previousSpaceToken: SpaceToken?

  
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
    
    let tokens = self.spaceSwitcher.spaceTokens
    
    if let previousToken = self.previousSpaceToken,
      tokens.contains(previousToken) {
      self.addButton(label: "last: ", forSpaceToken: previousToken)
    }
    
    for token in tokens {
      let isActive = (token == self.activeSpaceToken)
      self.addButton(label: isActive ? "*" : "", forSpaceToken: token)
    }
  }

  
  // MARK: - internals
  
  func addButton(label: String = "", forSpaceToken spaceToken: Int) {

    let title = "\(label) \(String(spaceToken))".trimmingCharacters(in: .whitespacesAndNewlines)

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
  
    
  // MARK: -
  var spaceSwitcher: SpaceSwitcher {
    return (NSApp.delegate as! AppDelegate).spaceSwitcher!
  }
  
}


// MARK: - responding to events

extension ViewController: SpaceChangeObserver {
  
  func onSpaceChanged() {
    
    // ensure we handle the event after SpaceSwitcher.
    DispatchQueue.main.async {

      self.activeSpaceToken = self.spaceSwitcher.spaceTokenForActiveSpace
    }
    
  }
  
}



// MARK: -

class FullScreenAnchorViewController: NSViewController {
  

  @IBAction func action_hideWindow(_ sender: Any) {
    self.view.window?.orderOut(self)
  }
  
}

