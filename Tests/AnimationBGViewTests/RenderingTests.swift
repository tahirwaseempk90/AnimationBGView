import SwiftUI
import XCTest
@testable import AnimationBGView

/// Renders the real view with `ImageRenderer` and checks the pixels.
@MainActor
final class RenderingTests: XCTestCase {
    private let base = PixelBuffer.RGBA(red: 0xFA, green: 0xEE, blue: 0xA3, alpha: 255)

    // MARK: - Coverage and colour

    func testBackgroundFillsItsWholeFrame() throws {
        for size in [DeviceSize.iPhone, DeviceSize.iPhoneLandscape, DeviceSize.card, CGSize(width: 37, height: 500)] {
            let pixels = try XCTUnwrap(BackgroundRendering.background(phase: .zero, size: size))
            XCTAssertEqual(pixels.width, Int(size.width))
            XCTAssertEqual(pixels.height, Int(size.height))
            XCTAssertFalse(pixels.hasTransparentPixels, "\(size)")
        }
    }

    func testAreasAwayFromTheLightsShowTheBaseColour() throws {
        let pixels = try XCTUnwrap(BackgroundRendering.background(phase: .zero, size: DeviceSize.iPhone))
        for (x, y) in [(0.5, 0.95), (0.05, 0.9), (0.95, 0.8)] {
            XCTAssertLessThanOrEqual(pixels.pixel(atFractionX: x, y: y).maximumDifference(from: base), 1, "at \(x), \(y)")
        }
    }

    func testCustomPaletteIsUsed() throws {
        var configuration = AnimatedBackgroundConfiguration.static
        configuration.palette = BackgroundColorPalette(base: Color(red: 1, green: 0, blue: 0), lights: [])
        configuration.vShape.isVisible = false
        let pixels = try XCTUnwrap(BackgroundRendering.background(configuration, phase: .zero, size: DeviceSize.card))
        let red = PixelBuffer.RGBA(red: 255, green: 0, blue: 0, alpha: 255)
        for (x, y) in [(0.1, 0.1), (0.5, 0.5), (0.9, 0.9)] {
            XCTAssertLessThanOrEqual(pixels.pixel(atFractionX: x, y: y).maximumDifference(from: red), 1)
        }
    }

    // MARK: - The V

    func testTheVShowsTheLightsAtFortyTwoPercent() throws {
        // Inside the V, the base colour is laid over the lights at 58%, so what remains of a light's
        // colour is 42% of what it would be without the V. Outside the V, nothing changes.
        let size = DeviceSize.iPhone
        var noV = AnimatedBackgroundConfiguration.default
        noV.vShape.isVisible = false
        let withV = try XCTUnwrap(BackgroundRendering.background(phase: 0.1, size: size))
        let without = try XCTUnwrap(BackgroundRendering.background(noV, phase: 0.1, size: size))

        let outline = VShapeOutline(geometry: .reference)
        let margin = 0.02   // Keeps samples clear of the soft edges.
        var checkedInside = 0
        var checkedOutside = 0
        for row in stride(from: 0.04, through: 1.2, by: 0.02) {
            for column in stride(from: 0.02, through: 0.98, by: 0.01) {
                let x = Int(column * Double(size.width)), y = Int(row * Double(size.width))
                guard y < Int(size.height) else { continue }
                let region = classify(u: column, v: row, outline: outline, margin: margin)
                let covered = withV.pixel(x: x, y: y), uncovered = without.pixel(x: x, y: y)
                switch region {
                case .band:
                    let deviation = [uncovered.red - base.red, uncovered.green - base.green, uncovered.blue - base.blue]
                    guard deviation.contains(where: { abs($0) >= 8 }) else { continue }
                    let remaining = [covered.red - base.red, covered.green - base.green, covered.blue - base.blue]
                    for (left, full) in zip(remaining, deviation) {
                        XCTAssertEqual(Double(left), 0.42 * Double(full), accuracy: 1.6, "at \(column), \(row)")
                    }
                    checkedInside += 1
                case .outside:
                    XCTAssertLessThanOrEqual(covered.maximumDifference(from: uncovered), 1, "at \(column), \(row)")
                    checkedOutside += 1
                case .edge:
                    continue
                }
            }
        }
        XCTAssertGreaterThan(checkedInside, 30, "Too few samples where a light passes behind the V")
        XCTAssertGreaterThan(checkedOutside, 500)
    }

    func testVKeepsItsProportionsAtEverySize() throws {
        for size in [CGSize(width: 390, height: 844), CGSize(width: 600, height: 1_299), CGSize(width: 1_024, height: 1_366)] {
            let pixels = try XCTUnwrap(BackgroundRendering.background(Self.geometryProbe(), phase: .zero, size: size))
            let width = Double(size.width)
            // The left stroke's outer edge, 0.3 widths down.
            let row = Int(0.3 * width)
            let edge = try XCTUnwrap(pixels.firstColumn(inRow: row) { $0.red < 128 })
            XCTAssertEqual(Double(edge) / width, 0.2497 + 0.3630 * (Double(row) + 0.5) / width, accuracy: 1.5 / width, "\(size)")
            // The vertex. Near a sharp point, antialiasing covers less than half a pixel, so the last
            // dark row is up to a few pixels above the exact tip.
            let bottom = Double(try XCTUnwrap(pixels.lastRow { $0.red < 128 }))
            XCTAssertLessThanOrEqual(bottom, 1.0676 * width + 0.5, "\(size)")
            XCTAssertGreaterThanOrEqual(bottom, 1.0676 * width - 3.5, "\(size)")
        }
    }

    func testFitKeepsTheWholeVInViewOnWideScreens() throws {
        let size = DeviceSize.iPhoneLandscape
        let pixels = try XCTUnwrap(BackgroundRendering.background(Self.geometryProbe(), phase: .zero, size: size))
        let unit = Double(size.height) / 1.2
        let bottom = try XCTUnwrap(pixels.lastRow { $0.red < 128 })
        XCTAssertLessThanOrEqual(Double(bottom), 1.0676 * unit + 0.5)
        XCTAssertGreaterThanOrEqual(Double(bottom), 1.0676 * unit - 3.5)
        XCTAssertLessThan(bottom, Int(size.height) - 1, "The vertex is above the bottom edge")
        // The composition is centred, so the V's outer edges are where the centred layout puts them.
        let origin = (Double(size.width) - unit) / 2
        let edge = try XCTUnwrap(pixels.firstColumn(inRow: 10) { $0.red < 128 })
        XCTAssertEqual(Double(edge), origin + (0.2497 + 0.3630 * 10.5 / unit) * unit, accuracy: 1.5)
    }

    func testFillWidthLetsTheVExtendPastTheBottom() throws {
        let size = DeviceSize.iPhoneLandscape
        let pixels = try XCTUnwrap(BackgroundRendering.background(Self.geometryProbe(scaling: .fillWidth), phase: .zero, size: size))
        XCTAssertEqual(pixels.lastRow { $0.red < 128 }, Int(size.height) - 1)
    }

    func testSoftEdgesSpreadOverTheConfiguredWidth() throws {
        let size = DeviceSize.iPhone
        let row = Int(0.3 * Double(size.width))
        func transitionWidth(softness: Double) throws -> Int {
            let pixels = try XCTUnwrap(BackgroundRendering.background(Self.geometryProbe(edgeSoftness: softness), phase: .zero, size: size))
            let edge = try XCTUnwrap(pixels.firstColumn(inRow: row) { $0.red < 128 })
            return ((edge - 12)...(edge + 12)).filter { (10...245).contains(pixels.pixel(x: $0, y: row).red) }.count
        }
        let crisp = try transitionWidth(softness: 0)
        let soft = try transitionWidth(softness: 0.0115)
        XCTAssertLessThanOrEqual(crisp, 2)
        // 1.15% of 393 points is 4.5 points, spread over the edge's slant.
        XCTAssertGreaterThanOrEqual(soft, 4)
        XCTAssertLessThanOrEqual(soft, 8)
    }

    func testRightToLeftLayoutDoesNotMirror() throws {
        let leftToRight = try XCTUnwrap(BackgroundRendering.background(phase: 0.2, size: DeviceSize.iPhone))
        let rightToLeft = try XCTUnwrap(BackgroundRendering.background(
            phase: 0.2,
            size: DeviceSize.iPhone,
            environment: RenderEnvironment(layoutDirection: .rightToLeft)
        ))
        XCTAssertLessThanOrEqual(leftToRight.maximumDifference(from: rightToLeft), 1)

        let shape = VShape().fill(Color.black).background(Color.white)
        let shapeLeftToRight = try XCTUnwrap(BackgroundRendering.pixels(of: shape, size: DeviceSize.card))
        let shapeRightToLeft = try XCTUnwrap(BackgroundRendering.pixels(
            of: shape,
            size: DeviceSize.card,
            environment: RenderEnvironment(layoutDirection: .rightToLeft)
        ))
        XCTAssertLessThanOrEqual(shapeLeftToRight.maximumDifference(from: shapeRightToLeft), 1)
    }

    // MARK: - Animation

    func testStillImagesAreDeterministic() throws {
        let first = try XCTUnwrap(BackgroundRendering.background(phase: 0.37, size: DeviceSize.iPhone))
        let second = try XCTUnwrap(BackgroundRendering.background(phase: 0.37, size: DeviceSize.iPhone))
        XCTAssertEqual(first.maximumDifference(from: second), 0)
    }

    func testColoursChangeOverTheCycle() throws {
        let start = try XCTUnwrap(BackgroundRendering.background(phase: 0, size: DeviceSize.iPhone))
        let half = try XCTUnwrap(BackgroundRendering.background(phase: 0.5, size: DeviceSize.iPhone))
        XCTAssertGreaterThan(start.maximumDifference(from: half), 15)
        // But the parts the lights never reach stay put.
        XCTAssertEqual(start.pixel(atFractionX: 0.5, y: 0.95), half.pixel(atFractionX: 0.5, y: 0.95))
    }

    func testTheLastFrameFlowsIntoTheFirst() throws {
        let size = CGSize(width: 196, height: 426)
        let end = try XCTUnwrap(BackgroundRendering.background(phase: AnimationPhase(1 - 1e-4), size: size))
        let start = try XCTUnwrap(BackgroundRendering.background(phase: .zero, size: size))
        let middle = try XCTUnwrap(BackgroundRendering.background(phase: AnimationPhase(0.5 - 1e-4), size: size))
        let afterMiddle = try XCTUnwrap(BackgroundRendering.background(phase: 0.5, size: size))
        // Five milliseconds of motion moves a gradient by a fraction of a pixel, which can change a
        // few pixels by a level or two through rounding. Crossing the loop point is no different.
        let acrossTheLoop = end.maximumDifference(from: start)
        let ordinaryStep = middle.maximumDifference(from: afterMiddle)
        XCTAssertLessThanOrEqual(acrossTheLoop, 3)
        XCTAssertLessThanOrEqual(acrossTheLoop, ordinaryStep + 1)

        // And a whole cycle later, the frame is identical.
        let duration = AnimationConfiguration.default.cycleDuration
        let now = try XCTUnwrap(BackgroundRendering.background(phase: .elapsed(12.3, cycleDuration: duration), size: size))
        let later = try XCTUnwrap(BackgroundRendering.background(phase: .elapsed(12.3 + duration, cycleDuration: duration), size: size))
        XCTAssertEqual(now.maximumDifference(from: later), 0)
    }

    func testFramesChangeGraduallyThroughTheWholeCycle() throws {
        // 120 frames a cycle is one every 0.43 s at normal speed, 13 times further apart than 30 fps.
        // Even so, no step, including the one from the last frame back to the first, is a jump.
        let size = CGSize(width: 196, height: 426)
        let count = 120
        let frames = try (0..<count).map { index in
            try XCTUnwrap(BackgroundRendering.background(phase: AnimationPhase(Double(index) / Double(count)), size: size))
        }
        var steps: [Int] = []
        for index in 0..<count {
            steps.append(frames[index].maximumDifference(from: frames[(index + 1) % count]))
        }
        let largest = try XCTUnwrap(steps.max())
        XCTAssertLessThanOrEqual(largest, 6)
        XCTAssertLessThanOrEqual(try XCTUnwrap(steps.last), largest, "The wrap-around step is no bigger than any other")
    }

    // MARK: - Helpers

    /// A white background with an opaque black V and no lights, for measuring the V.
    static func geometryProbe(scaling: CompositionScaling = .fit, edgeSoftness: Double = 0) -> AnimatedBackgroundConfiguration {
        var configuration = AnimatedBackgroundConfiguration.static
        configuration.palette = BackgroundColorPalette(base: .white, lights: [], vShape: .black)
        configuration.vShape.opacity = 1
        configuration.vShape.edgeSoftness = edgeSoftness
        configuration.scaling = scaling
        return configuration
    }

    private enum Region { case band, outside, edge }

    private func classify(u: Double, v: Double, outline: VShapeOutline, margin: Double) -> Region {
        let edges = [outline.outerLeft, outline.innerLeft, outline.innerRight, outline.outerRight]
        let distances = edges.map { abs(u - $0.u(at: v)) / (1 + $0.slope * $0.slope).squareRoot() }
        guard distances.allSatisfy({ $0 > margin }) else { return .edge }
        let insideOuter = u > outline.outerLeft.u(at: v) && u < outline.outerRight.u(at: v)
        let insideNotch = u > outline.innerLeft.u(at: v) && u < outline.innerRight.u(at: v)
        return insideOuter && !insideNotch ? .band : .outside
    }
}
