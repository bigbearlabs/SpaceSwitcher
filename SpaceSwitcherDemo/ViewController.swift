import Cocoa
import SpaceSwitcher
import BBLSpaces



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

    _ = self.spacesObservation
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
        let isCurrent = currents.contains(token)
        let isActive = self.state.activeSpaceToken == token
        self.addButton(label: "\(isCurrent ? "*" : "") \(isActive ? "*" : "") \(did) ", forSpaceToken: token)
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
  
  lazy var spacesObservation = {
    SpacesChangeObserver { spacesInfo in
      
      let (tokens, currents, active) = stateTuple(spacesInfo)
      
      var newState = self.state
      newState.spaceTokens = tokens
      newState.previousSpaceTokens = newState.currentSpaceTokens
      newState.currentSpaceTokens = currents
      newState.activeSpaceToken = active
      
      self.state = newState
    }
    
  }()
  
}

func stateTuple(_ spacesInfo: SpacesInfo) -> ([DisplayId : [SpaceToken]], [SpaceToken], SpaceToken) {
  
  let ts = spacesInfo.screens.map {
    ($0.displayId, $0.spaceIds.map { $0.intValue })
  }
  let states = Dictionary(uniqueKeysWithValues: ts)
  
  return (
    spacesByDisplay: states,
    currentSpaces: spacesInfo.currentSpaceIds.map { $0.intValue },
    activeSpace: spacesInfo.activeSpaceId
  )
}


// MARK: -

class FullScreenAnchorViewController: NSViewController {
  

  @IBAction func action_hideWindow(_ sender: Any) {
    self.view.window?.orderOut(self)
  }
  
}

