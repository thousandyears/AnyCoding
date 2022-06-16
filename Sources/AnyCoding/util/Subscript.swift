enum OptionalSubscriptError: Error {
	case pathDoesNotExist([CodingKey], description: String)
	case message(String)
	case other(Error)
}

extension Optional where Wrapped == Any {
	
	subscript(first: AnyCodingKey, rest: AnyCodingKey...) -> Any? {
		get { self[[first] + rest] }
		set { self[[first] + rest] = newValue }
	}
	
	subscript<C: Collection>(path: C) -> Any? where C.Element == CodingKey {
		get { try? get(path, from: self) }
		set { set(newValue, at: path, on: &self) }
	}
}

extension Dictionary where Key == String, Value == Any {
	
	subscript(first: AnyCodingKey, rest: AnyCodingKey...) -> Any? {
		get { self[[first] + rest] }
		set { self[[first] + rest] = newValue }
	}
	
	subscript<C: Collection>(path: C) -> Value? where C.Element == CodingKey {
		get { try? get(path) }
		set { set(newValue, at: path) }
	}
	
	func get<C: Collection>(_ path: C) throws -> Value where C.Element == CodingKey {
		guard let (head, remaining) = path.headAndTail else { return self }
		guard let value = self[head.stringValue] else {
			throw OptionalSubscriptError.pathDoesNotExist(
				Array(path),
				description: "\(path) → Key \(head.stringValue) does not exist at \(self)"
			)
		}
		return try _get(remaining, from: value)
	}
	
	mutating func set<C: Collection>(_ value: Value?, at path: C) where C.Element == CodingKey {
		guard let (head, remaining) = path.headAndTail else { return }
		let key = head.stringValue
		self[key] = _set(value, at: remaining, on: self[key] as Any)
	}
}

extension Array where Element == Any {
	
	subscript(first: AnyCodingKey, rest: AnyCodingKey...) -> Any? {
		get { self[[first] + rest] }
		set { self[[first] + rest] = newValue }
	}
	
	subscript<C: Collection>(path: C) -> Element? where C.Element == CodingKey {
		get { try? get(path) }
		set { set(newValue, at: path) }
	}
	
	func get<C: Collection>(_ path: C) throws -> Element where C.Element == CodingKey {
		guard let (head, remaining) = path.headAndTail else { return self }
		guard let idx = head.intValue.map(bidirectionalIndex) else {
			throw OptionalSubscriptError.pathDoesNotExist(
				.init(path),
				description: "\(path) → Path indexing into array \(self) must be an Int - got: \(head.stringValue)"
			)
		}
		guard indices.contains(idx) else {
			throw OptionalSubscriptError.message("\(path) → Array index '\(idx)' out of bounds")
		}
		return try _get(remaining, from: self[idx])
	}
	
	mutating func set<C: Collection>(_ value: Element?, at path: C) where C.Element == CodingKey {
		guard let (head, remaining) = path.headAndTail else { return }
		guard let idx = head.intValue.map(bidirectionalIndex) else { return }
		padded(to: idx, with: Any?.none as Any)
		self[idx] = _set(value, at: remaining, on: self[idx])
	}
	
	func bidirectionalIndex(_ idx: Int) -> Int {
		guard idx < 0 else { return idx }
		guard !isEmpty else { return 0 }
		return (count + idx) % count
	}
}

extension RangeReplaceableCollection where Self: BidirectionalCollection {
	
	fileprivate mutating func padded(to size: Int, with value: @autoclosure () -> Element) {
		guard !indices.contains(index(startIndex, offsetBy: size)) else { return }
		append(contentsOf: (0..<(1 + size - count)).map { _ in value() })
	}
}

private func get<T, C: Collection>(
	_ path: C,
	from any: Any?,
	as _: T.Type = T.self
) throws -> T? where C.Element == CodingKey {
	let any: Any = try _get(path, from: any)
	return try (any as? T).or(throw: OptionalSubscriptError.message("\(type(of: any)) is not \(T.self)"))
}

private func _get<C: Collection>(_ path: C, from any: Any?) throws -> Any where C.Element == CodingKey {
	switch any {
	case let array as [Any]:
		return try array.get(path)
	case let dictionary as [String: Any]:
		return try dictionary.get(path)
	case let fragment where path.isEmpty:
		return fragment as Any
	case let fragment:
		let description = String(describing: fragment)
		let type = type(of: fragment)
		throw OptionalSubscriptError.pathDoesNotExist(
			Array(path),
			description: "\(path) → Path indexing into \(description) of \(type) not allowed"
		)
	}
}

private func set<T, C: Collection>(_ value: T, at path: C, on any: inout Any?) where C.Element == CodingKey {
	any = _set(value, at: path, on: any)
}

private func _set<C: Collection>(_ value: Any?, at path: C, on any: Any?) -> Any where C.Element == CodingKey {
	guard let (crumb, _) = path.headAndTail else { return flattenOptionality(value as Any) }
	switch crumb {
	case _ where crumb.intValue != nil:
		var array = (any as? [Any]) ?? []
		array.set(value, at: path)
		return array
	case _:
		var dictionary = (any as? [String: Any]) ?? [:]
		dictionary.set(value, at: path)
		return dictionary
	}
}

extension Collection {
	
	fileprivate var headAndTail: (head: Element, tail: SubSequence)? {
		guard let head = first else { return nil }
		return (head, dropFirst())
	}
}

extension String {
	
	fileprivate func splitDotPath() -> [String] {
		isEmpty
		? []
		: split(separator: ".", omittingEmptySubsequences: true).map(String.init)
	}
}

extension Collection where Element == String {
	fileprivate var codingPath: [CodingKey] { map { AnyCodingKey($0) } }
}

extension Optional where Wrapped == Any {
	
	subscript(first: String, rest: String...) -> Any? {
		get { self[[first] + rest] }
		set { self[[first] + rest] = newValue }
	}
	
	subscript(dotPath string: String) -> Any? {
		get { self[string.splitDotPath()] }
		set { self[string.splitDotPath()] = newValue }
	}
	
	subscript<C: Collection>(_ collection: C) -> Any? where C.Element == String {
		get { self[collection.codingPath] }
		set { self[collection.codingPath] = newValue }
	}
}

extension Dictionary where Key == String, Value == Any {
	
	subscript(first: String, rest: String...) -> Any? {
		get { self[[first] + rest] }
		set { self[[first] + rest] = newValue }
	}
	
	subscript(dotPath string: String) -> Any? {
		get { self[string.splitDotPath()] }
		set { self[string.splitDotPath()] = newValue }
	}
	
	subscript<C: Collection>(_ collection: C) -> Value? where C.Element == String {
		get { self[collection.codingPath] }
		set { self[collection.codingPath] = newValue }
	}
}

extension Array where Element == Any {
	
	subscript(first: String, rest: String...) -> Any? {
		get { self[[first] + rest] }
		set { self[[first] + rest] = newValue }
	}
	
	subscript(dotPath string: String) -> Any? {
		get { self[string.splitDotPath()] }
		set { self[string.splitDotPath()] = newValue }
	}
	
	subscript<C: Collection>(_ collection: C) -> Element? where C.Element == String {
		get { self[collection.codingPath] }
		set { self[collection.codingPath] = newValue }
	}
}
