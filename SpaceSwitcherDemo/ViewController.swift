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
    
    let state = self.state

    let previousSpacesTuples = state.previousSpaceTokens.map {
      ("Back to Space \($0)", $0)
    }

    let currents = state.currentSpaceTokens
    let activeToken = state.activeSpaceToken
    let spacesTuples = state.spaceTokens.map { e -> [(String, SpaceToken)] in
      let (displayId, spaceTokens) = e
      
      return spaceTokens.map { token -> (String, SpaceToken) in
        let isCurrent = currents.contains(token)
        let isActive = token == activeToken
        return (
          "\(isCurrent ? "*" : "") \(isActive ? "*" : "") \(displayId)",
          token
        )
      }
    }
    
    let controlLabelTuples = previousSpacesTuples + spacesTuples.flatMap { $0 }
    
    let buttons = controlLabelTuples.map { e -> NSButton in
      let (label, spaceToken) = e
      return button(label: label, forSpaceToken: spaceToken)
    }
    
    for b in buttons {
      buttonsStackView.addView(b, in: .top)
    }
  }

  
  // MARK: - internals
  
  func button(label: String = "", forSpaceToken spaceToken: Int) -> NSButton {

    let title = "\(label) \(String(spaceToken))".trimmingCharacters(in: .whitespacesAndNewlines)

    let button = NSButton(
      title: title,
      target: self,
      action: #selector(switchToSpace(_:)))
    button.cell!.representedObject = spaceToken
    return button
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

class AnchorViewController: NSViewController {
  

  @IBAction func action_hideWindow(_ sender: Any) {
    self.view.window?.orderOut(self)
  }
  
}

