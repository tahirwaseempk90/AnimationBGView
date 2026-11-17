import SwiftUI
import XCTest

/// Compares a rendered image against a stored reference image.
///
/// Built on `ImageRenderer` rather than a snapshot library, so the package stays free of dependencies.
/// Rendering can differ between operating systems, so references are kept per platform and major
/// OS version, in `__Snapshots__/<platform>-<version>/`. On a combination with no references, these
/// tests skip instead of reporting false failures.
///
/// To record: `SNAPSHOT_RECORD=1 swift test --filter SnapshotTests`. With `xcodebuild`, set
/// `TEST_RUNNER_SNAPSHOT_RECORD=1` so the variable reaches the simulator.
@MainActor
func assertSnapshot(
    _ image: CGImage?,
    named name: String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    let image = try XCTUnwrap(image, "The view did not render", file: file, line: line)
    let reference = SnapshotLocation.directory.appendingPathComponent("\(name).png")

    if ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" {
        try PNGFile.write(image, to: reference)
        return
    }
    guard FileManager.default.fileExists(atPath: SnapshotLocation.directory.path) else {
        throw XCTSkip("No snapshots recorded for \(SnapshotLocation.directory.lastPathComponent).")
    }
    guard let stored = PNGFile.read(from: reference) else {
        XCTFail("Missing snapshot \(name). Record it with SNAPSHOT_RECORD=1.", file: file, line: line)
        return
    }
    let actualPixels = try XCTUnwrap(PixelBuffer(image), file: file, line: line)
    let referencePixels = try XCTUnwrap(PixelBuffer(stored), file: file, line: line)
    guard image.width == stored.width, image.height == stored.height else {
        XCTFail(
            "\(name): size changed from \(stored.width)x\(stored.height) to \(image.width)x\(image.height).",
            file: file,
            line: line
        )
        return
    }
    let difference = actualPixels.differingFraction(from: referencePixels, channelTolerance: SnapshotLocation.channelTolerance)
    if difference > SnapshotLocation.maximumDifferingFraction {
        let failed = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name)-actual.png")
        try PNGFile.write(image, to: failed)
        XCTFail(
            "\(name): \(String(format: "%.3f", difference * 100))% of pixels differ. Actual image: \(failed.path)",
            file: file,
            line: line
        )
    }
}

enum SnapshotLocation {
    /// Allows for rounding noise in gradients, but catches a light or an edge moving.
    static let channelTolerance = 3
    /// Moving the V by a single point changes more pixels than this.
    static let maximumDifferingFraction = 0.002

    static var directory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent("\(platform)-\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)")
    }

    private static var platform: String {
        #if targetEnvironment(macCatalyst)
        return "macCatalyst"
        #elseif os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #else
        return "other"
        #endif
    }
}
