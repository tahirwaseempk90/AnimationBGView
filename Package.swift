// swift-tools-version: 6.0
import PackageDescription

// The library needs only iOS 15 / macOS 12 APIs (`TimelineView`, `Canvas`), but iOS 16 / macOS 13 is
// what the package is built and tested against: the test suite renders the real view with
// `ImageRenderer`, which arrived in iOS 16 / macOS 13. macOS is declared so that `swift build` and
// `swift test` work from the command line, and because the test suite runs there.
let package = Package(
    name: "AnimationBGView",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "AnimationBGView", targets: ["AnimationBGView"])
    ],
    targets: [
        .target(name: "AnimationBGView"),
        .testTarget(
            name: "AnimationBGViewTests",
            dependencies: ["AnimationBGView"],
            exclude: ["__Snapshots__"]
        )
    ],
    swiftLanguageModes: [.v6]
)
