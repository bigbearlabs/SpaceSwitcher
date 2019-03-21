import BBLSpaces



class SpacesPrivateApiTool {
  
  var spaceIds: [SpaceToken] {
    return spacesBroker.probeResult()?.spaceIds() as? [SpaceToken] ?? []
  }
  
  var currentSpaceId: SpaceToken {
    return spacesBroker.currentSpaceId()
  }
  
  func placeAnchorWindowsInAllSpaces() -> [SpaceToken : NSWindowController] {
    var anchorWindowControllersBySpaceToken: [SpaceToken : NSWindowController] = [:]
    for spaceId in self.spaceIds {
      let anchorWindowController = self.placeAnchorWindow(inSpace: spaceId)
      anchorWindowControllersBySpaceToken[spaceId] = anchorWindowController
    }
    return anchorWindowControllersBySpaceToken
  }
  
  func placeAnchorWindow(inSpace spaceId: SpaceToken) -> NSWindowController {
    let anchorWindowController = anchorWindowVendor.newAnchorWindowController()
    setup(anchorWindowController: anchorWindowController)
    
    let windowNumber = anchorWindowController.window!.windowNumber
    spacesBroker.moveWindowNumber(CGWindowID(windowNumber), toSpaceId: spaceId)
    
    return anchorWindowController
  }


  let spacesBroker = SpacesBroker()

}
