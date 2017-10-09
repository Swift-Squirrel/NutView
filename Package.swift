// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NutView",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "NutView",
            targets: ["NutView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swift-Squirrel/SquirrelJSON.git", from: "0.1.0"),
        .package(url: "https://github.com/LeoNavel/Evaluation.git",  from: "0.2.1"),
        .package(url: "https://github.com/sharplet/Regex.git",  from: "1.1.0"),
        .package(url: "https://github.com/kylef/PathKit.git",  from: "0.8.0"),
        .package(url: "https://github.com/LeoNavel/Cache.git", from: "4.0.3")
    ],
    targets: [
        .target(
            name: "NutView",
            dependencies: ["SquirrelJSON", "Evaluation", "Regex", "Cache", "PathKit"]),
        .testTarget(
            name: "NutViewTests",
            dependencies: ["NutView"]),
    ]
)
