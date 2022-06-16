// swift-tools-version: 5.6

import PackageDescription

let package = Package(
	name: "AnyCoding",
	products: [
		.library(name: "AnyCoding", targets: ["AnyCoding"])
	],
	targets: [
		.target(name: "AnyCoding"),
		.testTarget(name: "AnyCodingTests", dependencies: ["AnyCoding"])
	]
)
