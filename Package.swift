// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pomo",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PomoCore", targets: ["PomoCore"]),
        .library(name: "PomoAgentKit", targets: ["PomoAgentKit"]),
        .executable(name: "pomo", targets: ["PomoCLI"]),
        .executable(name: "PomoAgent", targets: ["PomoAgent"]),
    ],
    targets: [
        .target(name: "PomoCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "PomoCLI", dependencies: ["PomoCore"]),
        .target(
            name: "PomoAgentKit",
            dependencies: ["PomoCore"],
            linkerSettings: [.linkedFramework("Security")]),
        .executableTarget(name: "PomoAgent", dependencies: ["PomoAgentKit"]),
        .testTarget(name: "PomoCoreTests", dependencies: ["PomoCore", "PomoAgentKit"]),
    ]
)
