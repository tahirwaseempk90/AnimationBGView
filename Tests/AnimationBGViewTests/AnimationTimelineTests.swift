import XCTest
@testable import AnimationBGView

final class AnimationTimelineTests: XCTestCase {
    private let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    func testPhaseAdvancesWithTime() {
        let timeline = AnimationTimeline(start: .zero, rate: 0.1, date: start)
        XCTAssertEqual(timeline.phase(at: at(2.5)).fraction, 0.25, accuracy: 1e-9)
        XCTAssertEqual(timeline.phase(at: at(12.5)).fraction, 0.25, accuracy: 1e-9)
    }

    func testStartsAtTheGivenPhase() {
        let timeline = AnimationTimeline(start: 0.6, rate: 0.1, date: start)
        XCTAssertEqual(timeline.phase(at: start).fraction, 0.6, accuracy: 1e-12)
    }

    func testDatesBeforeTheAnchorDoNotRunBackwards() {
        let timeline = AnimationTimeline(start: 0.4, rate: 0.1, date: start)
        XCTAssertEqual(timeline.phase(at: at(-30)).fraction, 0.4, accuracy: 1e-12)
    }

    func testChangingTheRateDoesNotJump() {
        var timeline = AnimationTimeline(start: .zero, rate: 1 / 51.5, date: start)
        let before = timeline.phase(at: at(3_000))
        timeline.setRate(4 / 51.5, at: at(3_000))
        XCTAssertEqual(timeline.phase(at: at(3_000)).fraction, before.fraction, accuracy: 1e-9)
        // And afterwards it moves at the new rate.
        let later = timeline.phase(at: at(3_001)).fraction
        XCTAssertEqual(AnimationPhase(later - before.fraction).fraction, 4 / 51.5, accuracy: 1e-9)
    }

    func testPausingHoldsTheCurrentPhase() {
        var timeline = AnimationTimeline(start: .zero, rate: 0.1, date: start)
        timeline.pause(at: at(2))
        XCTAssertEqual(timeline.phase(at: at(2)).fraction, 0.2, accuracy: 1e-9)
        XCTAssertEqual(timeline.phase(at: at(500)).fraction, 0.2, accuracy: 1e-9)
        XCTAssertFalse(timeline.isRunning)
    }

    func testResumingContinuesFromTheHeldPhase() {
        var timeline = AnimationTimeline(start: .zero, rate: 0.1, date: start)
        timeline.pause(at: at(2))
        timeline.resume(at: at(60))
        XCTAssertEqual(timeline.phase(at: at(60)).fraction, 0.2, accuracy: 1e-9)
        XCTAssertEqual(timeline.phase(at: at(61)).fraction, 0.3, accuracy: 1e-9)
    }

    func testPausingTwiceAndResumingTwiceAreHarmless() {
        var timeline = AnimationTimeline(start: .zero, rate: 0.1, date: start)
        timeline.pause(at: at(1))
        timeline.pause(at: at(5))
        XCTAssertEqual(timeline.phase(at: at(9)).fraction, 0.1, accuracy: 1e-9)
        timeline.resume(at: at(9))
        timeline.resume(at: at(12))
        XCTAssertEqual(timeline.phase(at: at(12)).fraction, 0.4, accuracy: 1e-9)
    }

    func testStillModeShowsTheStillPhaseAndResumesFromIt() {
        var timeline = AnimationTimeline(start: .zero, rate: 0.1, date: start)
        timeline.update(mode: .still, rate: 0.1, stillPhase: 0.3, at: at(4))
        XCTAssertEqual(timeline.phase(at: at(4)).fraction, 0.3, accuracy: 1e-12)
        XCTAssertEqual(timeline.phase(at: at(40)).fraction, 0.3, accuracy: 1e-12)

        // Turning animation back on starts from the still image, not from wherever the clock would be.
        timeline.update(mode: .running, rate: 0.1, stillPhase: 0.3, at: at(40))
        XCTAssertEqual(timeline.phase(at: at(40)).fraction, 0.3, accuracy: 1e-12)
        XCTAssertEqual(timeline.phase(at: at(41)).fraction, 0.4, accuracy: 1e-9)
    }

    func testPausedModeHoldsAndRunningModeResumes() {
        var timeline = AnimationTimeline(start: .zero, rate: 0.1, date: start)
        timeline.update(mode: .paused, rate: 0.1, stillPhase: .zero, at: at(3))
        XCTAssertEqual(timeline.phase(at: at(30)).fraction, 0.3, accuracy: 1e-9)
        timeline.update(mode: .running, rate: 0.2, stillPhase: .zero, at: at(30))
        XCTAssertEqual(timeline.phase(at: at(31)).fraction, 0.5, accuracy: 1e-9)
    }

    func testInvalidRatesStopTheClock() {
        for rate: Double in [-1, .nan, -.infinity] {
            let timeline = AnimationTimeline(start: 0.25, rate: rate, date: start)
            XCTAssertEqual(timeline.phase(at: at(100)).fraction, 0.25, accuracy: 1e-12, "rate \(rate)")
        }
        var timeline = AnimationTimeline(start: 0.25, rate: 0.1, date: start)
        timeline.setRate(.infinity, at: at(1))
        XCTAssertEqual(timeline.phase(at: at(50)).fraction, 0.35, accuracy: 1e-9)
    }

    func testStaysPreciseAfterRunningForDays() {
        let timeline = AnimationTimeline(start: .zero, rate: 1 / 51.5, date: start)
        let threeDays: TimeInterval = 3 * 24 * 3_600
        let phase = timeline.phase(at: at(threeDays))
        let expected = AnimationPhase(threeDays / 51.5)
        XCTAssertEqual(phase.fraction, expected.fraction, accuracy: 1e-6)
    }

    func testOneCycleLaterIsTheSameFrame() {
        let duration = 51.5
        let timeline = AnimationTimeline(start: 0.2, rate: 1 / duration, date: start)
        for seconds in stride(from: 0.0, to: 200, by: 13.7) {
            let difference = abs(timeline.phase(at: at(seconds)).fraction - timeline.phase(at: at(seconds + duration)).fraction)
            XCTAssertEqual(min(difference, 1 - difference), 0, accuracy: 1e-9)
        }
    }
}
