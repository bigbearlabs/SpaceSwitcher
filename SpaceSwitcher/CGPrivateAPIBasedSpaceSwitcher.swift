import BBLSpaces



public class CGPrivateAPIBasedSpaceSwitcher: SpaceSwitcher {
  
  let spacesBroker = SpacesBroker()
  
  public init() {}
  
  public var spaceTokenForCurrentSpace: SpaceToken? {
    return spacesBroker.probeResult()?.currentSpaceId()
  }
  
  public var spaceTokens: [SpaceToken] {
    return spacesBroker.probeResult()?.spaceIds() as? [SpaceToken] ?? []
  }
  
  
  public func switchToSpace(token: SpaceToken) {
    fatalError("TODO implement using CGSManagedDisplaySetCurrentSpace")
  }
  
}
