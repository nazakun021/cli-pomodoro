// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pomo",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PomoCore", targets: ["PomoCore"]),
        .executable(name: "pomo", targets: ["PomoCLI"]),
        .executable(name: "PomoAgent", targets: ["PomoAgent"]),
    ],
    targets: [
        .target(name: "PomoCore"),
        .executableTarget(name: "PomoCLI", dependencies: ["PomoCore"]),
        .executableTarget(name: "PomoAgent", dependencies: ["PomoCore"]),
        .testTarget(name: "PomoCoreTests", dependencies: ["PomoCore"]),
    ]
)