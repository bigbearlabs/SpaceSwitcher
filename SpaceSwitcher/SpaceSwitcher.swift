/// an opaque identifier for a space.
/// not to be confused with other types of space ids already used by the system.
public typealias SpaceToken = Int


public protocol SpaceSwitcher {
  func switchToSpace(token: SpaceToken)
}

public typealias DisplayId = String
