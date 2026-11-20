// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Waymark",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Waymark", targets: ["Waymark"])
    ],
    targets: [
        .target(name: "WaymarkCore"),
        .executableTarget(name: "Waymark", dependencies: ["WaymarkCore"]),
        .testTarget(name: "WaymarkCoreTests", dependencies: ["WaymarkCore"])
    ]
)
