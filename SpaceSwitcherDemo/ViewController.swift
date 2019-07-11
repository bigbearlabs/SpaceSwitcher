import Cocoa
import SpaceSwitcher


class ViewController: NSViewController {

  struct State {
    var spaceTokens: [DisplayId : [SpaceToken]]
    
    var currentSpaceTokens: [SpaceToken]
    var previousSpaceTokens: [SpaceToken]
    
    var activeSpaceToken: SpaceToken?
    
    init() {
      self.spaceTokens = [:]
      self.currentSpaceTokens = []
      self.previousSpaceTokens = []
      self.activeSpaceToken = nil
    }
  }
  
  var state = State() {
    didSet {
      self.refreshSwitchToSpaceButtons()
      
      for window in NSApp.windows {
        window.setIsVisible(true)
      }
    }
  }
  

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
    
    for previous in self.state.previousSpaceTokens {
      self.addButton(label: "last: ", forSpaceToken: previous)
    }
    
    let currents = self.state.currentSpaceTokens
    for e in self.state.spaceTokens {
      let (did, tokens) = e
      for token in tokens {
        let isActive = (currents.contains(token))
        self.addButton(label: "\(isActive ? "*" : "") \(did) ", forSpaceToken: token)
      }
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

      let (tokens, currents, active) = self.spaceSwitcher.stateTuple
      
      var newState = self.state
      newState.spaceTokens = tokens
      newState.previousSpaceTokens = newState.currentSpaceTokens
      newState.currentSpaceTokens = currents
      newState.activeSpaceToken = active
        
      self.state = newState
    }
    
  }
  
}



// MARK: -

class FullScreenAnchorViewController: NSViewController {
  

  @IBAction func action_hideWindow(_ sender: Any) {
    self.view.window?.orderOut(self)
  }
  
}

