public enum DecodingContainer: String {
  case keyed
  case unkeyed
  case singleValue
}

extension Decodable {
  
  public static var containerType: DecodingContainer {
    do {
      _ = try self.init(from: DecodingContainerDecoder())
      return .singleValue
    } catch let error as DecodingContainerDecoder.Container {
      return error.type
    } catch {
      fatalError("Impossible")
    }
  }
}

struct DecodingContainerDecoder: Decoder {
  
  var codingPath: [CodingKey] { [] }
  var userInfo: [CodingUserInfoKey: Any] { [:] }
  
  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
    throw Container.keyed
  }
  
  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    throw Container.unkeyed
  }
  
  func singleValueContainer() throws -> SingleValueDecodingContainer {
    throw Container.singleValue
  }
  
  fileprivate enum Container: Error {
    
    case keyed
    case unkeyed
    case singleValue
    
    var type: DecodingContainer {
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
}
