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
            url: "https://github.com/Navneet-Gupta-qaig/QSleeve_IOS_SDK/releases/download/v0.1.0/QSleeveSDK.xcframework.zip",
            checksum: "6d65b5604e375da4f3f2f4f2185133f822c982f86cb7100e0ec3bc2f90b6644d"
        )
    ]
)
