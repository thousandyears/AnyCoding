public struct CodableVoid: Codable, Equatable, Hashable, Identifiable {
  public var id: CodableVoid { self }
  public init() {}
}
