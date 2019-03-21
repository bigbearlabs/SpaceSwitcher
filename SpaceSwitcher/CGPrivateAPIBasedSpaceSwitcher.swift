import BBLSpaces



public class CGPrivateAPIBasedSpaceSwitcher: SpaceSwitcher, AnchorWindowOrchestrator {
  var anchorWindowControllers: [NSWindowController] {
    get {
      return Array(self.anchorWindowControllersBySpaceId.values)
    }
    set {
      for wc in newValue {
        let spaceId = spacesBroker.spaceIds(forWindowIds: [wc.window!.windowNumber])[0] as! Int
        self.anchorWindowControllersBySpaceId[spaceId] = wc
      }
    }
  }
  
  var anchorWindowControllersBySpaceId: [SpaceToken : NSWindowController] = [:]
  
  let spacesBroker = SpacesBroker()
  
  public init() {
    placeAnchorWindowsInAllSpaces()
  }
  
  public var spaceTokenForCurrentSpace: SpaceToken? {
    return spacesBroker.probeResult()?.currentSpaceId()
  }
  
  public var spaceTokens: [SpaceToken] {
    return spacesBroker.probeResult()?.spaceIds() as? [SpaceToken] ?? []
  }
  
  func anchorWindowController(spaceToken: SpaceToken) -> NSWindowController? {
    let o = self.anchorWindowControllersBySpaceId[spaceToken]
    return o
  }
  

  public func switchToSpace(token: SpaceToken) {
    self.activateAnchorWindow(forSpaceToken: token)
    
    ensureNoMultipleAnchorWindowsInSpace {
      
    }
  }
  
  
  func placeAnchorWindowsInAllSpaces() {
    for spaceId in self.spaceTokens {
      self.placeAnchorWindow(inSpace: spaceId)
    }
  }
  
  func placeAnchorWindow(inSpace spaceId: SpaceToken) {
    let anchorWindowController = anchorWindowVendor.newAnchorWindowController()
    setup(anchorWindowController: anchorWindowController)
    let windowNumber = anchorWindowController.window!.windowNumber
    spacesBroker.moveWindowNumber(CGWindowID(windowNumber), toSpaceId: spaceId)
    
    self.anchorWindowControllersBySpaceId[spaceId] = anchorWindowController
  }
  
}


func setup(anchorWindowController: NSWindowController) {
  anchorWindowController.window?.transparent = true
  anchorWindowController.window?.setIsVisible(true)
}

let anchorWindowVendor = AnchorWindowVendor()


class AnchorWindowVendor {
  
  func newAnchorWindowController() -> NSWindowController {
    let identifier = "AnchorWindowController"
    let controller = storyboard.instantiateController(withIdentifier: identifier) as! NSWindowController
    
    return controller
  }
  
  let storyboard = NSStoryboard(name: "AnchorWindows", bundle: Bundle(for: AnchorWindowVendor.self))
}
