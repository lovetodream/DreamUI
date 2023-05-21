// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "dream-ui",
    platforms: [.iOS(.v16), .watchOS(.v9), .tvOS(.v16), .macOS(.v13), .macCatalyst(.v16)],
    products: [
        .library(name: "DreamUI", targets: ["DreamUI"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "DreamUI", dependencies: []),
        .testTarget(name: "DreamUITests", dependencies: ["DreamUI"]),
    ]
)
