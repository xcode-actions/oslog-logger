// swift-tools-version:5.3
import PackageDescription


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
		], path: "Sources"),
		.testTarget(name: "OSLogLoggerTests", dependencies: ["OSLogLogger"], path: "Tests"),
	]
)
