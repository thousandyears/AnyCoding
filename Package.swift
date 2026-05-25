// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "AnyCoding",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .custom("android", versionString: "28.0"),
    .custom("linux", versionString: "1.0")
  ],
  products: [
    .library(name: "AnyCoding", targets: ["AnyCoding"])
  ],
  targets: [
    .target(name: "AnyCoding"),
    .testTarget(name: "AnyCodingTests", dependencies: ["AnyCoding"])
  ],
  swiftLanguageModes: [.v6]
)
