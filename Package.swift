// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Ink",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Ink",
            resources: [.process("Resources")]
        )
    ]
)
