// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "Swift_Express",
        products: [
            .library(name: "Swift_Express", targets: ["Swift_Express"]),
        ],
        dependencies: [
            // Dependencies declare other packages that this package depends on.
            // .package(url: /* package url */, from: "1.0.0"),

            .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
        ],
        targets: [
            // Targets are the basic building blocks of a package. A target can define a module or a test suite.
            // Targets can depend on other targets in this package, and on products in packages which this package depends on.
            .target(
                    name: "Swift_Express",
                    dependencies: [
                        .product(name: "NIO", package: "swift-nio"),
                        .product(name: "NIOHTTP1", package: "swift-nio")
                    ]),
            .target(
                    name: "Example",
                    dependencies: [
                        "Swift_Express"
                    ]),
            .testTarget(
                    name: "Swift_ExpressTests",
                    dependencies: ["Swift_Express"]),
        ]
)
