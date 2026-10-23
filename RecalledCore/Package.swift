// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RecalledCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "RecalledCore", targets: ["RecalledCore"])
    ],
    targets: [
        .target(name: "RecalledCore"),
        .testTarget(name: "RecalledCoreTests", dependencies: ["RecalledCore"])
    ]
)
