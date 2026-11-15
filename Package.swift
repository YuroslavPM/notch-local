// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchLocal",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "NotchLocal",
            path: "Sources/NotchLocal"
        )
    ]
)
