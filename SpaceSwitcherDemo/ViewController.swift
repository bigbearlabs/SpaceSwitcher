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
    
    spaceSwitcher.switchToSpace(token: spaceToken)
  }

  
  func refreshSwitchToSpaceButtons() {
    self.removeAllSwitchToSpaceButtons()
    
    let state = self.state

    let _spaceSwitchLabelTuples = spaceSwitchLabelTuples(from: state)

    let buttons = _spaceSwitchLabelTuples.map { e -> NSButton in
      let (label, spaceToken) = e
      return button(label: label, forSpaceToken: spaceToken)
    }
    
    for b in buttons {
      buttonsStackView.addView(b, in: .top)
    }
  }

  
  // MARK: - internals
  
  func button(label: String = "", forSpaceToken spaceToken: Int) -> NSButton {

    let title = "\(label)".trimmingCharacters(in: .whitespacesAndNewlines)

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
  
  lazy var spacesObservation = {
    SpacesChangeObserver { spacesInfo in
      
      self.state = stateTuple(spacesInfo, self.state.previousSpaceTokens)
    }
    
  }()
  
}

func stateTuple(_ spacesInfo: SpacesInfo, _ previousSpaces: [SpaceToken])
  -> ViewController.State {
  
  let ts = spacesInfo.screens.map {
    ($0.displayId, $0.spaceIds.map { $0.intValue })
  }
  let states = Dictionary(uniqueKeysWithValues: ts)
  
  let t = (
    spacesByDisplay: states,
    activeSpace: spacesInfo.activeSpaceId,
    currentSpaces: spacesInfo.currentSpaceIds.map { $0.intValue },
    previousSpaces: previousSpaces
  )
    
  let (
    spacesByDisplay,
    activeSpace,
    currentSpaces,
    previousSpaces
  ) = t
  
  var newState = ViewController.State()
  newState.spaceTokens = spacesByDisplay
  newState.activeSpaceToken = activeSpace
  newState.currentSpaceTokens = currentSpaces
  newState.previousSpaceTokens = previousSpaces
  return newState
}


func spaceSwitchLabelTuples(from state: ViewController.State) -> [(String, SpaceToken)] {
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
        "\(isCurrent ? "*" : "") \(isActive ? "*" : "") \(displayId) \(token)",
        token
      )
    }
  }
  
  let controlLabelTuples = previousSpacesTuples + spacesTuples.flatMap { $0 }
  
  return controlLabelTuples
}


// MARK: -
