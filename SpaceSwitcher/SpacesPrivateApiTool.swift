import BBLSpaces



class SpacesPrivateApiTool {
  
  var spaceIds: [SpaceToken] {
    let spaceIds = spacesBroker.probeResult.screens.flatMap { $0.spaceIds }
    return spaceIds as? [SpaceToken] ?? []
  }
  
  var activeSpaceId: SpaceToken {
    return spacesBroker.activeSpaceId
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
    
    let window = anchorWindowController.window!
    let windowNumber = window.windowNumber

    // * position anchor window within the screen's visible frame.
    
    let spacesInfo = spacesBroker.probeResult
    let screenInfo = spacesInfo.screens.first {
      $0.spaceIds.map { $0.intValue }
        .contains(spaceId)
    }!
    let matchingScreen = NSScreen.screens.first {
      let displayRef = CGDisplayCreateUUIDFromDisplayID($0.directDisplayId)?.takeUnretainedValue()
      let displayRefString = CFUUIDCreateString(nil, displayRef!)
      return displayRefString == screenInfo.displayId as CFString
    }!
    
    let screenOrigin = matchingScreen.visibleFrame.origin
    let newFrame = CGRect(origin: screenOrigin, size: window.frame.size)
    
    window.setFrame(newFrame, display: true)

    // * move to the target space.
    
    spacesBroker.moveWindowNumber(CGWindowID(windowNumber), toSpaceId: spaceId)
    
    print("\(anchorWindowController) place to space \(spaceId), origin \(screenOrigin)")
    
    return anchorWindowController
  }


  let spacesBroker = SpacesBroker()

}



extension NSScreen {
  
  var directDisplayId: CGDirectDisplayID {
    let val = (self.deviceDescription as NSDictionary).value(forKey: "NSScreenNumber") as! NSNumber
    return val.uint32Value
  }
}
