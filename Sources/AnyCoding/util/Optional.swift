@usableFromInline protocol OptionalProtocol: ExpressibleByNilLiteral {
  static var null: OptionalProtocol { get }
  var flattened: Any? { get }
}

extension OptionalProtocol {
  @usableFromInline var isNil: Bool { flattened == nil }
  @usableFromInline var isNotNil: Bool { flattened != nil }
}

func flattenOptionality(_ any: Any) -> Any {
  (any as? OptionalProtocol)?.flattened ?? any
}

func isNil(_ any: Any?) -> Bool {
  switch any.flattened {
  case .none:
    return true
  case .some:
    return false
  }
}

extension Optional: OptionalProtocol {

  @usableFromInline static var null: OptionalProtocol { Optional.none as OptionalProtocol }

  @usableFromInline var flattened: Any? {
    switch self {
    case nil:
      return nil
    case let wrapped?:
      return (wrapped as? OptionalProtocol)?.flattened ?? wrapped
    }
  }

  func or(throw error: @autoclosure () -> Error) throws -> Wrapped {
    guard let wrapped = self else { throw error() }
    return wrapped
  }
}
