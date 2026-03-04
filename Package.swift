// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QSleeveSDK",
    platforms: [
        .iOS(.v26),.macOS(.v26)
      ],
    products: [
        .library(name: "QSleeveSDK", targets: ["QSleeveSDK"])
    ],
    targets: [
        .binaryTarget(
            name: "QSleeveSDK",
            url: "https://github.com/Navneet-Gupta-qaig/QSDK/releases/download/v0.0.1/QSleeveSDK.xcframework.zip",
            checksum: "f3e8d4d240162eff1a6e61a66a0076ac93717bad8d47e869513a7d92d8a7edd6"
        )
    ]
)
