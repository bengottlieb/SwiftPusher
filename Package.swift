// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPusher",
     platforms: [
              .macOS(.v12),
              .iOS(.v15),
              .watchOS(.v7)
         ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftPusher",
            targets: ["SwiftPusher"]),
    ],
    dependencies: [
		.package(name: "SwiftJWT", url: "https://github.com/Kitura/Swift-JWT", from: "4.0.0"),
		.package(name: "Nearby", url: "https://github.com/ios-tooling/nearby", from: "0.10.11"),
		.package(name: "Suite", url: "https://github.com/ios-tooling/suite", from: "1.0.79"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "SwiftPusher", dependencies: [
			"SwiftJWT",
			.product(name: "Nearby", package: "Nearby"),
			.product(name: "Suite", package: "Suite")]),
    ]
)
