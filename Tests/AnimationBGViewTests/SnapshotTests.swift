import SwiftUI
import XCTest
@testable import AnimationBGView

/// Compares renders against stored images, to catch any visible change. See `SnapshotAssertion.swift`.
///
/// Images are rendered at half scale: the background is made of smooth gradients, so this still
/// catches a light or an edge moving, while keeping the stored images small.
@MainActor
final class SnapshotTests: XCTestCase {
    private let scale = RenderEnvironment(displayScale: 0.5)

    func testPhasesThroughTheCycle() throws {
        for phase in [0.0, 0.25, 0.5, 0.75] {
            try snapshot(.default, phase: AnimationPhase(phase), size: DeviceSize.iPhone, named: "iphone-phase-\(Int(phase * 100))")
        }
    }

    func testDeviceSizes() throws {
        try snapshot(.default, phase: .zero, size: DeviceSize.iPhoneSE, named: "iphone-se")
        try snapshot(.default, phase: .zero, size: DeviceSize.iPhoneProMax, named: "iphone-pro-max")
        try snapshot(.default, phase: .zero, size: DeviceSize.iPhoneLandscape, named: "iphone-landscape")
        try snapshot(.default, phase: .zero, size: DeviceSize.iPadPortrait, named: "ipad-portrait")
        try snapshot(.default, phase: .zero, size: DeviceSize.iPadLandscape, named: "ipad-landscape")
        try snapshot(.default, phase: .zero, size: DeviceSize.card, named: "card")
    }

    func testCustomisations() throws {
        var mint = AnimatedBackgroundConfiguration.default
        mint.palette = BackgroundColorPalette(
            base: Color(red: 0.91, green: 0.97, blue: 0.94),
            lights: [Color(red: 0.55, green: 0.85, blue: 0.75), Color(red: 0.62, green: 0.80, blue: 0.93),
                     Color(red: 0.80, green: 0.92, blue: 0.62), Color(red: 0.55, green: 0.72, blue: 0.70)]
        )
        try snapshot(mint, phase: .zero, size: DeviceSize.iPhone, named: "custom-palette")

        var noV = AnimatedBackgroundConfiguration.default
        noV.vShape.isVisible = false
        try snapshot(noV, phase: .zero, size: DeviceSize.iPhone, named: "no-v")

        var strong = AnimatedBackgroundConfiguration.default
        strong.gradient.intensity = 1.25
        strong.vShape.opacity = 0.75
        try snapshot(strong, phase: .zero, size: DeviceSize.iPhone, named: "strong")

        var fill = AnimatedBackgroundConfiguration.default
        fill.scaling = .fillWidth
        try snapshot(fill, phase: .zero, size: DeviceSize.iPhoneLandscape, named: "iphone-landscape-fill-width")
    }

    private func snapshot(
        _ configuration: AnimatedBackgroundConfiguration,
        phase: AnimationPhase,
        size: CGSize,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        var still = configuration
        still.motion.isEnabled = false
        still.motion.staticPhase = phase
        let image = BackgroundRendering.image(of: AnimatedBackgroundView(configuration: still), size: size, environment: scale)
        try assertSnapshot(image, named: name, file: file, line: line)
    }
}
