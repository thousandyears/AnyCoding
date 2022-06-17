@testable import AnyCoding
import XCTest

final class AnyCodingTests: XCTestCase {

	func test_bidirectional_index() throws {

		let empty = [Any]()
		XCTAssertEqual(empty.bidirectionalIndex(4), 4)
		XCTAssertEqual(empty.bidirectionalIndex(10), 10)
		XCTAssertEqual(empty.bidirectionalIndex(11), 11)
		XCTAssertEqual(empty.bidirectionalIndex(-1), 0)

		let array1 = Array(0...5) as [Any]
		XCTAssertEqual(array1.count, 6)
		XCTAssertEqual(array1.bidirectionalIndex(5), 5)
		XCTAssertEqual(array1.bidirectionalIndex(-1), 5)

		let array2 = Array(0...10) as [Any]
		XCTAssertEqual(array2.count, 11)
		XCTAssertEqual(array2.bidirectionalIndex(4), 4)
		XCTAssertEqual(array2.bidirectionalIndex(9), 9)
		XCTAssertEqual(array2.bidirectionalIndex(10), 10)
	}

	func test_coding() throws {

		struct Test: Codable, Equatable {
			let bool: Bool
			let int: Int?
			let string: String
			let date: Date
			let url: URL
			let deeply: Deep
			let ints: [Int?]
			let nested: [Deep.Nested]
			let optionalNested: [Deep.Nested?]
			let keyedNested: [String: Deep.Nested]
			let keyedOptionalNested: [String: Deep.Nested?]
			let nilInt: Int?

			struct Deep: Codable, Equatable {

				let nested: Nested?

				struct Nested: Codable, Equatable {

					enum Container: Codable, Equatable {
						case contained(value: String)
					}

					let bool: Bool
					let int: Int
					let string: String?
					let date: Date?
					let urls: [URL]
					let container: Container?
				}
			}
		}

		let url = URL(string: "https://example.com")!

		let nested = Test.Deep.Nested(
			bool: false,
			int: 1,
			string: "first",
			date: nil,
			urls: [url, url],
			container: .contained(
				value: "nested-container"
			)
		)

		let value = Test(
			bool: true,
			int: nil,
			string: "📀!",
			date: Date.distantPast,
			url: url,
			deeply: .init(nested: nested),
			ints: [nil, 1, 2, 3],
			nested: [nested, nested],
			optionalNested: [nested, nil, nested],
			keyedNested: ["first": nested],
			keyedOptionalNested: ["first": nil, "second": nested],
			nilInt: 3
		)

		assertCoding(value)
		assertCoding(Optional.some(value))
		assertCoding([value, value])
		assertCoding(["1": value, "2": value])
	}

	func assertCoding<T: Codable & Equatable>(_ value: T, _ file: StaticString = #file, _ line: UInt = #line) {
		do {
			let encoded = try XCTUnwrap(AnyEncoder().encode(value), file: file, line: line)
			let decoded = try AnyDecoder().decode(T.self, from: encoded)
			XCTAssertEqual(value, decoded, file: file, line: line)

			let encoder = JSONEncoder()
			encoder.dateEncodingStrategy = .secondsSince1970
			let json_encoded = try JSONSerialization.jsonObject(with: encoder.encode(decoded))
			let re_decoded = try AnyDecoder().decode(T.self, from: json_encoded)
			XCTAssertEqual(value, re_decoded, file: file, line: line)

			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .secondsSince1970
			let json_decoded = try decoder.decode(T.self, from: JSONSerialization.data(withJSONObject: encoded))
			XCTAssertEqual(value, json_decoded, file: file, line: line)

			let empty = try EmptyDecoder().decode(T.self)
			_ = try AnyEncoder().encode(empty)
		} catch {
			XCTFail("\(error)", file: file, line: line)
		}
	}
}
