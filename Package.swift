// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipShot",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClipShot",
            path: "Sources/ClipShot"
        )
    ]
)
