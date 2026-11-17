import XCTest
@testable import AnimationBGView

final class AnimationConfigurationTests: XCTestCase {
    func testDefaultsMatchTheReference() {
        let animation = AnimationConfiguration.default
        XCTAssertTrue(animation.isEnabled)
        XCTAssertEqual(animation.cycleDuration, 51.5)
        XCTAssertEqual(animation.speed, 1)
        XCTAssertEqual(animation.intensity, 1)
        XCTAssertEqual(animation.frameRate, 30)
        XCTAssertEqual(animation.staticPhase, .zero)
        XCTAssertEqual(animation.reduceMotion, .followsSystem)
        XCTAssertTrue(animation.pausesWhenInactive)
    }

    func testStaticPresetOnlyTurnsOffAnimation() {
        var expected = AnimationConfiguration.default
        expected.isEnabled = false
        XCTAssertEqual(AnimationConfiguration.static, expected)
    }

    func testCustomValuesAreStoredUnchanged() {
        // Sliders bind to these, so out-of-range values must round-trip; they're only clamped when used.
        var animation = AnimationConfiguration()
        animation.cycleDuration = 0.1
        animation.speed = -3
        animation.frameRate = 500
        XCTAssertEqual(animation.cycleDuration, 0.1)
        XCTAssertEqual(animation.speed, -3)
        XCTAssertEqual(animation.frameRate, 500)
    }

    func testOutOfRangeValuesAreClampedWhenUsed() {
        var animation = AnimationConfiguration()
        animation.cycleDuration = 0.1
        animation.speed = 100
        animation.intensity = -1
        animation.frameRate = 0
        XCTAssertEqual(animation.resolvedCycleDuration, 1)
        XCTAssertEqual(animation.resolvedSpeed, 20)
        XCTAssertEqual(animation.resolvedIntensity, 0)
        XCTAssertEqual(animation.resolvedFrameRate, 1)

        animation.cycleDuration = 1_000_000
        animation.speed = -1
        animation.intensity = 9
        animation.frameRate = 1_000
        XCTAssertEqual(animation.resolvedCycleDuration, 3_600)
        XCTAssertEqual(animation.resolvedSpeed, 0)
        XCTAssertEqual(animation.resolvedIntensity, 2)
        XCTAssertEqual(animation.resolvedFrameRate, 120)
    }

    func testNonFiniteValuesFallBackToDefaults() {
        var animation = AnimationConfiguration()
        animation.cycleDuration = .nan
        animation.speed = .infinity
        animation.intensity = .nan
        animation.frameRate = -.infinity
        XCTAssertEqual(animation.resolvedCycleDuration, 51.5)
        XCTAssertEqual(animation.resolvedSpeed, 1)
        XCTAssertEqual(animation.resolvedIntensity, 1)
        XCTAssertEqual(animation.resolvedFrameRate, 30)
        XCTAssertTrue(animation.cyclesPerSecond.isFinite)
        XCTAssertTrue(animation.frameInterval.isFinite)
    }

    func testRateAndFrameInterval() {
        var animation = AnimationConfiguration()
        XCTAssertEqual(animation.cyclesPerSecond, 1 / 51.5, accuracy: 1e-12)
        XCTAssertEqual(animation.frameInterval, 1.0 / 30, accuracy: 1e-12)
        animation.speed = 2
        XCTAssertEqual(animation.cyclesPerSecond, 2 / 51.5, accuracy: 1e-12)
        animation.speed = 0
        XCTAssertEqual(animation.cyclesPerSecond, 0)
    }

    func testReduceMotionPolicy() {
        XCTAssertTrue(ReduceMotionPolicy.followsSystem.reducesMotion(systemSetting: true))
        XCTAssertFalse(ReduceMotionPolicy.followsSystem.reducesMotion(systemSetting: false))
        XCTAssertTrue(ReduceMotionPolicy.always.reducesMotion(systemSetting: false))
        XCTAssertFalse(ReduceMotionPolicy.never.reducesMotion(systemSetting: true))
    }

    func testPlaybackMode() {
        let animation = AnimationConfiguration.default
        XCTAssertEqual(PlaybackMode(motion: animation, systemReducesMotion: false, sceneIsActive: true), .running)
        XCTAssertEqual(PlaybackMode(motion: animation, systemReducesMotion: true, sceneIsActive: true), .still)
        XCTAssertEqual(PlaybackMode(motion: animation, systemReducesMotion: false, sceneIsActive: false), .paused)
        XCTAssertEqual(PlaybackMode(motion: .static, systemReducesMotion: false, sceneIsActive: true), .still)

        var ignoresSetting = animation
        ignoresSetting.reduceMotion = .never
        XCTAssertEqual(PlaybackMode(motion: ignoresSetting, systemReducesMotion: true, sceneIsActive: true), .running)

        var alwaysReduced = animation
        alwaysReduced.reduceMotion = .always
        XCTAssertEqual(PlaybackMode(motion: alwaysReduced, systemReducesMotion: false, sceneIsActive: true), .still)

        var keepsRunning = animation
        keepsRunning.pausesWhenInactive = false
        XCTAssertEqual(PlaybackMode(motion: keepsRunning, systemReducesMotion: false, sceneIsActive: false), .running)
    }

    func testBackgroundConfigurationDefaults() {
        let configuration = AnimatedBackgroundConfiguration.default
        XCTAssertEqual(configuration.palette, .reference)
        XCTAssertEqual(configuration.motion, .default)
        XCTAssertEqual(configuration.vShape, .default)
        XCTAssertEqual(configuration.gradient, .default)
        XCTAssertEqual(configuration.scaling, .fit)
        XCTAssertTrue(configuration.ignoresSafeArea)
        XCTAssertEqual(AnimatedBackgroundConfiguration.static.motion, .static)
        XCTAssertNotEqual(AnimatedBackgroundConfiguration.static, .default)
    }

    func testGradientAndVShapeDefaultsAndClamping() {
        XCTAssertEqual(GradientConfiguration.default.intensity, 1)
        XCTAssertEqual(GradientConfiguration.default.softness, 1)
        XCTAssertEqual(GradientConfiguration.default.lights, GradientLight.reference)
        XCTAssertEqual(GradientConfiguration(intensity: 5, softness: 0).resolvedIntensity, 2)
        XCTAssertEqual(GradientConfiguration(intensity: 5, softness: 0).resolvedSoftness, 0.25)
        XCTAssertEqual(GradientConfiguration(intensity: .nan, softness: .nan).resolvedIntensity, 1)

        let vShape = VShapeConfiguration.default
        XCTAssertTrue(vShape.isVisible)
        XCTAssertEqual(vShape.opacity, 0.58)
        XCTAssertEqual(vShape.scale, 1)
        XCTAssertEqual(vShape.edgeSoftness, 0.0115)
        XCTAssertEqual(vShape.geometry, .reference)
        XCTAssertFalse(VShapeConfiguration.hidden.isVisible)
        XCTAssertEqual(VShapeConfiguration(opacity: 4, scale: 100, edgeSoftness: -1).resolvedOpacity, 1)
        XCTAssertEqual(VShapeConfiguration(opacity: 4, scale: 100, edgeSoftness: -1).resolvedScale, 3)
        XCTAssertEqual(VShapeConfiguration(opacity: 4, scale: 100, edgeSoftness: -1).resolvedEdgeSoftness, 0)
        XCTAssertEqual(VShapeConfiguration(opacity: .nan, scale: .nan, edgeSoftness: .nan).resolvedScale, 1)
    }
}
