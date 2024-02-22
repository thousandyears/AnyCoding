public enum EncodingContainer: String {
  case keyed
  case unkeyed
  case singleValue
}

extension Encodable {
  
  public var containerType: EncodingContainer { ContainerTypeEncoder().container(self) }
}

private enum ContainerType: Error {
  case keyed, unkeyed, singleValue
}

extension ContainerType {
  var type: EncodingContainer {
    switch self {
    case .keyed:
      return .keyed
    case .unkeyed:
      return .unkeyed
    case .singleValue:
      return .singleValue
    }
  }
}

struct ContainerTypeEncoder: Encoder, UnsupportedEncoderValues {
  
  func container<T>(_ this: T) -> EncodingContainer where T: Encodable {
    do {
      try this.encode(to: ContainerTypeEncoder())
      return .singleValue
    } catch let error as ContainerType {
      return error.type
    } catch {
      fatalError("Impossible")
    }
  }
}

extension ContainerTypeEncoder {
  func container<Key>(
    keyedBy type: Key.Type
  ) -> KeyedEncodingContainer<Key> where Key: CodingKey { KeyedEncodingContainer(KeyedContainer<Key>()) }
  func unkeyedContainer() -> UnkeyedEncodingContainer { UnkeyedContainer() }
  func singleValueContainer() -> SingleValueEncodingContainer { SingleValueContainer() }
}

extension ContainerTypeEncoder {
  struct KeyedContainer<Key>: UnsupportedEncoderValues where Key: CodingKey {}
}

extension ContainerTypeEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
  func encodeNil(forKey key: Key) throws { throw ContainerType.keyed }
  mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable { throw ContainerType.keyed }
}

extension ContainerTypeEncoder {
  struct SingleValueContainer: UnsupportedEncoderValues {}
}

extension ContainerTypeEncoder.SingleValueContainer: SingleValueEncodingContainer {
  func encodeNil() throws { throw ContainerType.singleValue }
  func encode<T>(_ value: T) throws where T: Encodable { throw ContainerType.singleValue }
}

extension ContainerTypeEncoder {
  struct UnkeyedContainer: UnsupportedEncoderValues { var count: Int = 0 }
}

extension ContainerTypeEncoder.UnkeyedContainer: UnkeyedEncodingContainer {
  mutating func encodeNil() throws { throw ContainerType.unkeyed }
  mutating func encode<T>(_ value: T) throws where T: Encodable { throw ContainerType.unkeyed }
}

private func unsupported(_ function: String = #function) -> Never {
  fatalError("\(function) isn't supported by ContainerTypeEncoder")
}

private protocol UnsupportedEncoderValues {
  var codingPath: [CodingKey] { get }
  var userInfo: [CodingUserInfoKey: Any] { get }
}

extension UnsupportedEncoderValues {
  var codingPath: [CodingKey] { unsupported() }
  var userInfo: [CodingUserInfoKey: Any] { unsupported() }
}

extension ContainerTypeEncoder.KeyedContainer {
  mutating func nestedContainer<NestedKey>(
    keyedBy keyType: NestedKey.Type,
    forKey key: Key
  ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey { unsupported() }
  mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer { unsupported() }
  func superEncoder() -> Encoder { unsupported() }
  func superEncoder(forKey key: Key) -> Encoder { unsupported() }
}

extension ContainerTypeEncoder.UnkeyedContainer {
  mutating func nestedContainer<NestedKey>(
    keyedBy keyType: NestedKey.Type
  ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey { unsupported() }
  mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { unsupported() }
  func superEncoder() -> Encoder { unsupported() }
}
