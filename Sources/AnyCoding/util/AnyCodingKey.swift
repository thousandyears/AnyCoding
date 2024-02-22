public struct AnyCodingKey: CodingKey {
  
  public var stringValue: String, intValue: Int?
  
  public init?(intValue: Int) {
    (self.intValue, stringValue) = (intValue, intValue.description)
  }
  
  public init?(stringValue: String) {
    (intValue, self.stringValue) = (nil, stringValue)
  }
}

extension AnyCodingKey {
  
  public init<K>(_ key: K) where K: CodingKey {
    (intValue, stringValue) = (key.intValue, key.stringValue)
  }
  
  public init(_ int: Int) {
    self.init(intValue: int)!
  }
  
  public init(_ string: String) {
    self.init(stringValue: string)!
  }
}

extension AnyCodingKey: ExpressibleByStringLiteral {
  
  public init(stringLiteral value: String) {
    self.init(stringValue: value)!
  }
}

extension AnyCodingKey: ExpressibleByIntegerLiteral {
  
  public init(integerLiteral value: Int) {
    self.init(intValue: value)!
  }
}
