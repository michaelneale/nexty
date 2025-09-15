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
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Goose",
            dependencies: [
                .product(name: "HotKey", package: "HotKey"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Goose/Goose",
            exclude: [
                "Info.plist",
                "Goose.entitlements"
            ],
            resources: [
                .process("Assets.xcassets"),
            ]
        ),
        .testTarget(
            name: "GooseTests",
            dependencies: ["Goose"],
            path: "Goose/GooseTests"
        ),
    ]
)
