// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VUDialDemo",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "VUDialDemo",
            dependencies: [
                .product(name: "VUDial", package: "VUDial")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
