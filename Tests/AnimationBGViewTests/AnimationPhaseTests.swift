import XCTest
@testable import AnimationBGView

final class AnimationPhaseTests: XCTestCase {
    func testValuesWrapIntoOneCycle() {
        XCTAssertEqual(AnimationPhase(0.25).fraction, 0.25)
        XCTAssertEqual(AnimationPhase(1.25).fraction, 0.25, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase(-0.75).fraction, 0.25, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase(7).fraction, 0)
    }

    func testOneIsTheSameMomentAsZero() {
        XCTAssertEqual(AnimationPhase(1), .zero)
        XCTAssertEqual(AnimationPhase(-1), .zero)
    }

    func testTinyNegativeValuesDoNotRoundUpToOne() {
        // `x - floor(x)` is exactly 1 for these, which would be outside 0..<1.
        for value in [-1e-17, -Double.leastNonzeroMagnitude, -1e-300] {
            let phase = AnimationPhase(value)
            XCTAssertGreaterThanOrEqual(phase.fraction, 0)
            XCTAssertLessThan(phase.fraction, 1, "\(value)")
        }
    }

    func testNonFiniteValuesBecomeZero() {
        XCTAssertEqual(AnimationPhase(.nan), .zero)
        XCTAssertEqual(AnimationPhase(.infinity), .zero)
        XCTAssertEqual(AnimationPhase(-.infinity), .zero)
    }

    func testLiterals() {
        let half: AnimationPhase = 0.5
        let whole: AnimationPhase = 3
        XCTAssertEqual(half.fraction, 0.5)
        XCTAssertEqual(whole, .zero)
    }

    func testRadians() {
        XCTAssertEqual(AnimationPhase(0.25).radians, .pi / 2, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase.zero.radians, 0)
    }

    func testAdvancingWrapsAround() {
        XCTAssertEqual(AnimationPhase(0.9).advanced(by: 0.2).fraction, 0.1, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase(0.1).advanced(by: -0.2).fraction, 0.9, accuracy: 1e-12)
    }

    func testElapsedTimeWithTheDefaultCycle() {
        let duration = AnimationConfiguration.default.cycleDuration
        XCTAssertEqual(AnimationPhase.elapsed(duration / 2, cycleDuration: duration).fraction, 0.5, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase.elapsed(duration / 4, cycleDuration: duration, speed: 2).fraction, 0.5, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase.elapsed(duration / 4, cycleDuration: duration, from: 0.5).fraction, 0.75, accuracy: 1e-12)
    }

    func testEveryCycleEndsWhereTheNextBegins() {
        let duration = 51.5
        for start in stride(from: 0.0, to: 120, by: 7.3) {
            let phase = AnimationPhase.elapsed(start, cycleDuration: duration)
            let oneCycleLater = AnimationPhase.elapsed(start + duration, cycleDuration: duration)
            let tenCyclesLater = AnimationPhase.elapsed(start + 10 * duration, cycleDuration: duration)
            XCTAssertEqual(circularDistance(phase, oneCycleLater), 0, accuracy: 1e-9)
            XCTAssertEqual(circularDistance(phase, tenCyclesLater), 0, accuracy: 1e-9)
        }
    }

    func testElapsedSanitizesItsInput() {
        // The cycle can't be shorter than a second, and speed can't be negative.
        XCTAssertEqual(AnimationPhase.elapsed(0.5, cycleDuration: 0).fraction, 0.5, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase.elapsed(10, cycleDuration: 51.5, speed: -1, from: 0.3).fraction, 0.3, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase.elapsed(.nan, cycleDuration: 51.5, from: 0.3).fraction, 0.3, accuracy: 1e-12)
        XCTAssertEqual(AnimationPhase.elapsed(10, cycleDuration: .nan, from: 0.3), AnimationPhase.elapsed(10, cycleDuration: 51.5, from: 0.3))
    }

    private func circularDistance(_ first: AnimationPhase, _ second: AnimationPhase) -> Double {
        let difference = abs(first.fraction - second.fraction)
        return min(difference, 1 - difference)
    }
}
