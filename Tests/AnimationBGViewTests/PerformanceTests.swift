import SwiftUI
import XCTest
@testable import AnimationBGView

/// Catches large regressions in the cost of a frame.
///
/// These render offscreen with `ImageRenderer`, so the absolute times aren't what a device sees on
/// screen. They're a stable way to notice if a change makes each frame do much more work.
@MainActor
final class PerformanceTests: XCTestCase {
    func testWorkOutsideDrawingIsTiny() {
        // Everything the clock and the layout do for one frame, 10,000 times over.
        let configuration = AnimatedBackgroundConfiguration.default
        let timeline = AnimationTimeline(start: .zero, rate: configuration.motion.cyclesPerSecond, date: Date())
        let start = Date()
        var lights = 0
        for frame in 0..<10_000 {
            let phase = timeline.phase(at: start.addingTimeInterval(Double(frame) / 30))
            lights += ColorFieldRenderer.resolvedLights(phase: phase, size: DeviceSize.iPhone, configuration: configuration).count
        }
        let perFrame = Date().timeIntervalSince(start) / 10_000
        XCTAssertEqual(lights, 40_000)
        XCTAssertLessThan(perFrame, 0.000_5, "Resolving a frame took \(perFrame * 1_000) ms")
    }

    func testRenderingAFrame() throws {
        // One full render of a phone-sized frame at 3x, which includes the V layer and the view
        // hierarchy as well as the four gradients.
        let environment = RenderEnvironment(displayScale: 3)
        _ = BackgroundRendering.background(phase: .zero, size: DeviceSize.iPhone, environment: environment)
        let frames = 10
        let start = Date()
        for index in 0..<frames {
            let image = BackgroundRendering.image(
                of: AnimatedBackgroundView(configuration: still(at: Double(index) / Double(frames))),
                size: DeviceSize.iPhone,
                environment: environment
            )
            XCTAssertNotNil(image)
        }
        let perFrame = Date().timeIntervalSince(start) / Double(frames)
        print("Offscreen render of a 393 × 852 pt frame at 3x: \(String(format: "%.1f", perFrame * 1_000)) ms")
        XCTAssertLessThan(perFrame, 0.5, "A frame took \(perFrame * 1_000) ms to render")
    }

    private func still(at phase: Double) -> AnimatedBackgroundConfiguration {
        var configuration = AnimatedBackgroundConfiguration.static
        configuration.motion.staticPhase = AnimationPhase(phase)
        return configuration
    }
}
