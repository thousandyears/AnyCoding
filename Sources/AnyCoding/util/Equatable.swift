public func isEqual(_ x: Any, _ y: Any) -> Bool {
	func f<LHS>(_ lhs: LHS) -> Bool {
		switch Wrapper<LHS>.self {
		case let p as AnyEquatable.Type:
			return p._isEqual(x, y)
		case let c as AnyEquatableContainer.Type:
			return c._isEqual(x, y)
		default:
			return false
		}
	}
	return _openExistential(x, do: f)
}

private protocol AnyEquatable {
	static func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool
}

private protocol AnyEquatableContainer {
	static func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool
}

private enum Wrapper<T> {}

extension Wrapper: AnyEquatable where T: Equatable {
	static func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
		guard let l = lhs as? T, let r = rhs as? T else { return false }
		return l == r
	}
}

extension Wrapper: AnyEquatableContainer where T: AnyEquatable {
	static func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool { T._isEqual(lhs, rhs) }
}

extension Dictionary: AnyEquatable {
	fileprivate static func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
		guard let l = lhs as? [Key: Any], let r = rhs as? [Key: Any] else { return false }
		return l.allSatisfy { k, v in
			r[k].map { isEqual($0, v) } ?? false
		}
	}
}

extension Array: AnyEquatable {
	fileprivate static func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
		guard let l = lhs as? [Element], let r = rhs as? [Element] else { return false }
		return zip(l, r).allSatisfy(isEqual)
	}
}

extension Optional: AnyEquatable {
	
	fileprivate static func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
		isEqual(flattenOptionality(lhs), flattenOptionality(rhs))
	}
}
