# AnyCoding

AnyCoding is a small Swift package for moving directly between `Codable` values and dynamic `Any` trees.

It is useful when a boundary already gives you dictionaries, arrays, fragments or `JSONSerialization` output, but the rest of your code wants normal Swift models. The package provides custom `Encoder` and `Decoder` implementations that walk those values in memory instead of serializing them into `Data` just so `JSONDecoder` can parse them again.

## Why

Swift's `Codable` APIs are strongest when both sides know the concrete type. Many integration points are less tidy:

- `JSONSerialization` returns `[String: Any]`, `[Any]` and fragments.
- Plugin, scripting and rule systems often pass dynamic values around.
- Tests and fixtures are easier to write as dictionary literals.
- Some app code needs to inspect, edit and then decode a payload.

AnyCoding keeps those boundaries small and cheap. Decode dynamic input into concrete models when you can, encode models back to dynamic values when you need to, and use `AnyJSON` when the shape is intentionally fluid.

## Why Not JSONEncoder and JSONDecoder?

`JSONEncoder` and `JSONDecoder` are the right tools when the boundary is bytes: files, network bodies, logs and other places where JSON text is the format you need to exchange.

They are awkward when the value is already an in-memory tree. A `[String: Any]`, `[Any]` or fragment has to be serialized into `Data` before it can be decoded, and an encoded model has to be parsed back out of `Data` before it can be inspected, edited or passed to APIs that expect dynamic values. That extra hop costs work and makes dynamic traversal harder to express.

AnyCoding is for the in-memory case:

- decode directly from dictionaries, arrays, fragments and `JSONSerialization` output.
- encode directly into dictionaries, arrays, fragments and `NSNull`.
- traverse and edit dynamic values before choosing a concrete type.
- convert parts of a payload without decoding the whole value up front.
- add domain-specific conversions by subclassing `AnyDecoder` and overriding `convert`.

Swift Compute uses this shape for its `_JSON` package: typed values can be encoded into a JSON value through `AnyEncoder`, and JSON values can be decoded back into models through `AnyDecoder`, without first round-tripping through `Data`.

BlockchainNamespace uses the same extension point for domain decoding. Its custom decoder converts strings, tags and references into domain types while still falling back to the standard AnyCoding conversions for ordinary JSON-shaped values.

## What It Provides

- `AnyDecoder`: decodes `Any` trees into `Decodable` values without a `Data` round trip.
- `AnyEncoder`: encodes `Encodable` values into `Any` trees without producing JSON bytes.
- `AnyJSON`: a lightweight dynamic wrapper with literal support, path access and Codable bridging.
- `EmptyDecoder`: creates empty/default instances of `Decodable` values.
- Path subscripting helpers for dictionaries, arrays and optional `Any` values.

## Installation

Add the package to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/thousandyears/AnyCoding.git", branch: "trunk")
```

Then add `AnyCoding` to your target dependencies:

```swift
.product(name: "AnyCoding", package: "AnyCoding")
```

## Examples

Decode an untyped payload into a concrete model without first serializing it:

```swift
import AnyCoding
import Foundation

struct Profile: Codable, Equatable {
  var name: String
  var age: Int
  var website: URL
}

let payload: [String: Any] = [
  "name": "Ada",
  "age": 36,
  "website": "https://example.com"
]

let profile = try AnyDecoder().decode(Profile.self, from: payload)
```

Encode a concrete model back into an inspectable `Any` tree:

```swift
let encoded = try AnyEncoder().encode(profile)

// encoded is a [String: Any] tree containing String, Int and URL-as-String values.
// It can be inspected or edited immediately; there are no JSON bytes to parse first.
```

Use `AnyJSON` when the shape is dynamic and you want path access before typed decoding:

```swift
var json: AnyJSON = [
  "profile": [
    "name": "Ada",
    "tags": ["maths", "computing"]
  ]
]

let name = try json.profile.name.as(String.self)
let tags: [String] = try json.profile.tags.decode(using: AnyDecoder())
```

Create empty values for tests, placeholders or progressive construction:

```swift
let empty = try EmptyDecoder().decode(Profile.self)
```

## Conversion Rules

`AnyEncoder` and `AnyDecoder` include practical conversions while walking the `Any` tree:

- `URL` encodes as its absolute string and decodes from a string.
- `Date` encodes as seconds since 1970 and decodes from a time interval.
- `Data` can decode from JSON data using `JSONSerialization`.
- `NSNumber` can decode into standard numeric and boolean types.
- `RawRepresentable` values can decode from their raw value.
- `nil` and `NSNull` are treated as null-like values.

## Platforms

AnyCoding uses Swift 6.3 and supports macOS 10.15+, iOS 13+, Android and Linux.

The package conditionally exposes Combine's `TopLevelEncoder` and `TopLevelDecoder` conformances on platforms where Combine is available. Core decoding and encoding does not require Combine.

CI runs the SwiftPM test suite on Linux and macOS 26. Android support is kept buildable, but Android is not part of the default pull-request CI.

## Development

Run the test suite with:

```sh
swift test
```

Useful platform checks:

```sh
swift build --target AnyCoding --triple arm64-apple-ios18.0 --sdk "$(xcrun --sdk iphoneos --show-sdk-path)"
swift build --target AnyCoding --swift-sdk aarch64-unknown-linux-android28 --static-swift-stdlib
```

## Philosophy

AnyCoding is deliberately small. It is not a new JSON model, a schema system or a replacement for `Codable`.

The aim is to avoid treating `Data` as an artificial checkpoint. If your real boundary is JSON text, use `JSONEncoder` and `JSONDecoder`. If your real boundary is already an `Any` tree, AnyCoding lets you traverse, convert and return to typed Swift without paying for a stringify-and-parse cycle.
