// swift-tools-version:5.8
import PackageDescription


//let swiftSettings: [SwiftSetting] = []
let swiftSettings: [SwiftSetting] = [.enableExperimentalFeature("StrictConcurrency")]

let package = Package(
	name: "oslog-logger",
	products: [
		.library(name: "OSLogLogger", targets: ["OSLogLogger"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
	],
	targets: [
		.target(name: "OSLogLogger", dependencies: [
			.product(name: "Logging",   package: "swift-log"),
		], path: "Sources", exclude: ["OSLogLogger+NoSendable.swift"], swiftSettings: swiftSettings),
		.testTarget(name: "OSLogLoggerTests", dependencies: ["OSLogLogger"], path: "Tests", swiftSettings: swiftSettings),
	]
)
