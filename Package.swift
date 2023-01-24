// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPusher",
     platforms: [
              .macOS(.v11),
              .iOS(.v14),
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
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "SwiftPusher", dependencies: []),
    ]
)
