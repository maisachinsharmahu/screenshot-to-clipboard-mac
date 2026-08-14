// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenshotToClipboard",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ScreenshotToClipboard",
            path: "Sources/ScreenshotToClipboard"
        )
    ]
)
