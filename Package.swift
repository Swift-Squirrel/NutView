// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "NutView",
    products: [
        .library(
            name: "NutView",
            targets: ["NutView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swift-Squirrel/SquirrelJSON.git", from: "0.1.2"),
        .package(url: "https://github.com/Swift-Squirrel/Squirrel-Core.git", from: "0.1.1"),
        .package(url: "https://github.com/Swift-Squirrel/Evaluation.git",  from: "0.3.1"),
        .package(url: "https://github.com/sharplet/Regex.git",  from: "1.1.0"),
        .package(url: "https://github.com/kylef/PathKit.git",  from: "0.8.0"),
        .package(url: "https://github.com/LeoNavel/Cache.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "NutView",
            dependencies: ["SquirrelJSON", "Evaluation", "Regex", "SquirrelCache", "PathKit", "SquirrelCore"]),

        .testTarget(
            name: "NutViewTests",
            dependencies: ["NutView"]),
        .testTarget(
            name: "NutViewIntegrationTests",
            dependencies: ["NutView"]),
    ]
)
