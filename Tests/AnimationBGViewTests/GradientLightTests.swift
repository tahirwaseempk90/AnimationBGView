import SwiftUI
import XCTest
@testable import AnimationBGView

final class GradientLightTests: XCTestCase {
    func testEveryLightReturnsToItsStartAtTheEndOfTheCycle() {
        for light in GradientLight.reference {
            let start = light.center(at: .zero)
            let almostEnd = light.center(at: AnimationPhase(1 - 1e-7))
            XCTAssertLessThan(distance(start, almostEnd), 1e-5)
            let afterOneCycle = light.center(at: .elapsed(51.5, cycleDuration: 51.5))
            XCTAssertLessThan(distance(start, afterOneCycle), 1e-9)
        }
    }

    func testLightsMoveSmoothly() {
        // At 30 frames per second, one frame is 1/1545 of the default cycle.
        let step = 1.0 / (30 * 51.5)
        for light in GradientLight.reference {
            let largestRadius = max(Double(light.orbitRadii.width), Double(light.orbitRadii.height))
            for index in 0..<200 {
                let phase = AnimationPhase(Double(index) / 200)
                let moved = distance(light.center(at: phase), light.center(at: phase.advanced(by: step)))
                XCTAssertLessThanOrEqual(moved, 2 * .pi * largestRadius * step * 1.0001)
            }
        }
    }

    func testReferenceLightsMoveCounterClockwise() {
        for light in GradientLight.reference {
            // When a light is at three o'clock on its ellipse, it moves up next. y points down.
            let atThreeOClock = AnimationPhase(light.startAngle.radians / (2 * .pi))
            let position = light.center(at: atThreeOClock)
            XCTAssertEqual(position.x, light.orbitCenter.x + light.orbitRadii.width, accuracy: 1e-9)
            XCTAssertEqual(position.y, light.orbitCenter.y, accuracy: 1e-9)
            XCTAssertLessThan(light.center(at: atThreeOClock.advanced(by: 0.01)).y, light.orbitCenter.y)
        }
    }

    func testNegativeRevolutionsMoveClockwiseAndZeroStaysStill() {
        var light = GradientLight.referenceGolden
        light.revolutions = -1
        let atThreeOClock = AnimationPhase(-light.startAngle.radians / (2 * .pi))
        XCTAssertEqual(light.center(at: atThreeOClock).y, light.orbitCenter.y, accuracy: 1e-9)
        XCTAssertGreaterThan(light.center(at: atThreeOClock.advanced(by: 0.01)).y, light.orbitCenter.y)

        light.revolutions = 0
        XCTAssertEqual(light.center(at: 0.1), light.center(at: 0.7))
    }

    func testTwoRevolutionsAlsoLoop() {
        var light = GradientLight.referencePeach
        light.revolutions = 2
        XCTAssertLessThan(distance(light.center(at: .zero), light.center(at: 0.5)), 1e-9)
    }

    func testTravelScalesTheEllipse() {
        let light = GradientLight.referenceTan
        let phase: AnimationPhase = 0.3
        let normal = light.center(at: phase)
        XCTAssertEqual(light.center(at: phase, travel: 0), light.orbitCenter)
        let doubled = light.center(at: phase, travel: 2)
        XCTAssertEqual(doubled.x - light.orbitCenter.x, 2 * (normal.x - light.orbitCenter.x), accuracy: 1e-9)
        XCTAssertEqual(doubled.y - light.orbitCenter.y, 2 * (normal.y - light.orbitCenter.y), accuracy: 1e-9)
        XCTAssertEqual(light.center(at: phase, travel: 50), doubled, "Travel is limited to 2")
        XCTAssertEqual(light.center(at: phase, travel: .nan), normal, "Invalid travel falls back to 1")
    }

    func testInvalidLightValuesStillGiveFinitePositions() {
        let light = GradientLight(
            orbitCenter: CGPoint(x: CGFloat.nan, y: .infinity),
            orbitRadii: CGSize(width: -1, height: CGFloat.nan),
            startAngle: .radians(.nan),
            size: .nan,
            peakOpacity: .nan
        )
        let position = light.center(at: 0.4)
        XCTAssertTrue(position.x.isFinite)
        XCTAssertTrue(position.y.isFinite)
    }

    func testPhaseZeroMatchesTheArrangementOfTheColourReference() {
        // Color.png: golden at the upper right, green-yellow at the upper left, peach at the lower
        // right, and tan at the lower left.
        let greenYellow = GradientLight.referenceGreenYellow.center(at: .zero)
        let golden = GradientLight.referenceGolden.center(at: .zero)
        let peach = GradientLight.referencePeach.center(at: .zero)
        let tan = GradientLight.referenceTan.center(at: .zero)
        XCTAssertGreaterThan(golden.x, greenYellow.x)
        XCTAssertLessThan(golden.y, peach.y)
        XCTAssertLessThan(golden.y, tan.y)
        XCTAssertGreaterThan(peach.x, tan.x)
        XCTAssertLessThan(greenYellow.y, tan.y)
        XCTAssertGreaterThan(peach.y, greenYellow.y)
    }

    func testLightsStayAroundTheMiddleOfTheV() {
        // The lights were measured circling the V's notch and right side, never the far left.
        for light in GradientLight.reference {
            for index in 0..<100 {
                let position = light.center(at: AnimationPhase(Double(index) / 100))
                XCTAssertGreaterThan(position.x, 0.38)
                XCTAssertLessThan(position.x, 1.0)
                XCTAssertGreaterThan(position.y, 0.2)
                XCTAssertLessThan(position.y, 0.63)
            }
        }
    }

    // MARK: - Resolved lights

    func testResolvedLightsInPoints() {
        let size = CGSize(width: 390, height: 844)
        let lights = ColorFieldRenderer.resolvedLights(phase: .zero, size: size, configuration: .default)
        XCTAssertEqual(lights.count, 4)
        for (resolved, light) in zip(lights, GradientLight.reference) {
            let expected = light.center(at: .zero)
            XCTAssertEqual(resolved.center.x, expected.x * 390, accuracy: 1e-6)
            XCTAssertEqual(resolved.center.y, expected.y * 390, accuracy: 1e-6)
            XCTAssertEqual(resolved.radius, light.size * 3 * 390, accuracy: 1e-6)
            XCTAssertEqual(resolved.opacity, 0.8, accuracy: 1e-12)
        }
        XCTAssertEqual(lights.map(\.color), BackgroundColorPalette.reference.lights)
    }

    func testIntensityAndSoftness() {
        let size = CGSize(width: 390, height: 844)
        var configuration = AnimatedBackgroundConfiguration.default
        configuration.gradient.intensity = 0
        XCTAssertTrue(ColorFieldRenderer.resolvedLights(phase: .zero, size: size, configuration: configuration).isEmpty)

        configuration.gradient.intensity = 2
        XCTAssertTrue(ColorFieldRenderer.resolvedLights(phase: .zero, size: size, configuration: configuration).allSatisfy { $0.opacity == 1 })

        configuration.gradient.intensity = 0.5
        configuration.gradient.softness = 2
        let soft = ColorFieldRenderer.resolvedLights(phase: .zero, size: size, configuration: configuration)
        XCTAssertEqual(soft[0].opacity, 0.4, accuracy: 1e-12)
        XCTAssertEqual(soft[0].radius, GradientLight.referenceGreenYellow.size * 3 * 390 * 2, accuracy: 1e-6)
    }

    func testPaletteColoursAreAssignedInOrderAndRepeat() {
        var configuration = AnimatedBackgroundConfiguration.default
        configuration.palette = BackgroundColorPalette(base: .white, lights: [.red, .blue])
        let lights = ColorFieldRenderer.resolvedLights(phase: .zero, size: CGSize(width: 300, height: 600), configuration: configuration)
        XCTAssertEqual(lights.map(\.color), [.red, .blue, .red, .blue])

        configuration.palette = BackgroundColorPalette(base: .white, lights: [])
        XCTAssertTrue(ColorFieldRenderer.resolvedLights(phase: .zero, size: CGSize(width: 300, height: 600), configuration: configuration).isEmpty)
    }

    func testNoLightsForAnEmptyView() {
        XCTAssertTrue(ColorFieldRenderer.resolvedLights(phase: .zero, size: .zero, configuration: .default).isEmpty)
        XCTAssertTrue(ColorFieldRenderer.resolvedLights(phase: .zero, size: CGSize(width: CGFloat.nan, height: 100), configuration: .default).isEmpty)
    }

    // MARK: - Falloff

    func testGaussianFalloff() {
        let stops = GaussianFalloff.stops
        XCTAssertEqual(stops.count, GaussianFalloff.stopCount)
        XCTAssertEqual(stops.first?.location, 0)
        XCTAssertEqual(stops.first?.opacity ?? 0, 1, accuracy: 1e-12)
        XCTAssertEqual(stops.last?.location, 1)
        XCTAssertEqual(stops.last?.opacity ?? 1, 0, accuracy: 1e-12)
        XCTAssertTrue(zip(stops, stops.dropFirst()).allSatisfy { $0.opacity > $1.opacity && $0.location < $1.location })
    }

    func testFalloffFollowsAGaussian() {
        // Within 1.5% of the true curve, rescaled to reach zero at three standard deviations.
        let floor = exp(-4.5)
        for distance in stride(from: 0.0, through: 3, by: 0.05) {
            let exact = (exp(-0.5 * distance * distance) - floor) / (1 - floor)
            XCTAssertEqual(GaussianFalloff.relativeOpacity(atDistance: distance), exact, accuracy: 0.015, "at \(distance)σ")
        }
        XCTAssertEqual(GaussianFalloff.relativeOpacity(atDistance: 0), 1)
        XCTAssertEqual(GaussianFalloff.relativeOpacity(atDistance: 4), 0)
        XCTAssertEqual(GaussianFalloff.relativeOpacity(atDistance: -1), 1)
        XCTAssertEqual(GaussianFalloff.relativeOpacity(atDistance: .nan), 0)
    }

    private func distance(_ first: CGPoint, _ second: CGPoint) -> Double {
        Double(hypot(first.x - second.x, first.y - second.y))
    }
}
