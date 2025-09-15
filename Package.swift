// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Goose",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Goose",
            targets: ["Goose"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "Goose",
            dependencies: [],
            path: "Goose/Goose",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "GooseTests",
            dependencies: ["Goose"],
            path: "Goose/GooseTests"
        ),
    ]
)
