// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VUDial",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // VUDial library for controlling VU Dial hardware
        .library(
            name: "VUDial",
            targets: ["VUDial"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/armadsen/ORSSerialPort.git", from: "2.1.0"),
    ],
    targets: [
        // Core library target - import this in your app
        .target(
            name: "VUDial",
            dependencies: [
                .product(name: "ORSSerial", package: "ORSSerialPort")
            ]
        ),
        // Demo app target (for development/testing)
        .executableTarget(
            name: "VUDialApp",
            dependencies: ["VUDial"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
