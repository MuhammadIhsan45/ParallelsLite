// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ParallelsLite",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ParallelsLite",
            targets: ["ParallelsLite"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ParallelsLite",
            dependencies: [],
            path: "Sources"
        )
    ]
)
