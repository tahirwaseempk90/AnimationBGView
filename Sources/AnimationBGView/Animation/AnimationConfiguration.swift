import Foundation

/// How the background moves.
///
/// The defaults reproduce the reference animation: one full cycle every 51.5 seconds, drawn at up to
/// 30 frames per second. Values outside a property's documented range are clamped when the
/// background draws, so a stray slider value can never break it.
///
/// ```swift
/// var configuration = AnimatedBackgroundConfiguration()
/// configuration.motion.speed = 2           // Twice as fast.
/// configuration.motion.intensity = 0.5     // The lights travel half as far.
/// ```
public struct AnimationConfiguration: Equatable, Sendable {
    /// Whether the background moves. When `false`, it shows ``staticPhase`` as a still image.
    public var isEnabled: Bool

    /// How long one full cycle takes at normal speed, in seconds. From 1 to 3,600; the default is 51.5.
    ///
    /// The default was measured from the reference recording. Every moving part completes a whole
    /// number of turns per cycle, so the end of one cycle flows into the start of the next.
    public var cycleDuration: TimeInterval

    /// A multiplier for the playback rate. From 0 to 20; the default is 1.
    ///
    /// `0` holds the current frame. Changing the speed while the background is running continues
    /// from the frame on screen, without a jump.
    public var speed: Double

    /// How far the lights travel along their paths, as a multiplier. From 0 to 2; the default is 1.
    ///
    /// `0` keeps every light at the centre of its path, and `2` doubles the distance it travels.
    /// To change how strong the colours are instead, use ``GradientConfiguration/intensity``.
    public var intensity: Double

    /// The highest number of frames drawn per second. From 1 to 120; the default is 30.
    ///
    /// The motion is slow, so 30 frames per second looks smooth while drawing half as often as a
    /// 60 Hz display would. Lower it to save more power.
    public var frameRate: Double

    /// The frame shown when the background isn't animating, and the frame it starts from.
    ///
    /// The default, `0`, matches the arrangement in the reference colour image: golden light at the
    /// upper right, green-yellow at the upper left, peach at the lower right, and tan at the lower left.
    public var staticPhase: AnimationPhase

    /// How the background responds to the Reduce Motion accessibility setting.
    public var reduceMotion: ReduceMotionPolicy

    /// Whether the background stops drawing while its scene isn't active. The default is `true`.
    ///
    /// When the scene becomes active again, the animation continues from the frame where it stopped.
    public var pausesWhenInactive: Bool

    /// Creates an animation configuration. Every parameter has a default that matches the reference.
    public init(
        isEnabled: Bool = true,
        cycleDuration: TimeInterval = 51.5,
        speed: Double = 1,
        intensity: Double = 1,
        frameRate: Double = 30,
        staticPhase: AnimationPhase = .zero,
        reduceMotion: ReduceMotionPolicy = .followsSystem,
        pausesWhenInactive: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.cycleDuration = cycleDuration
        self.speed = speed
        self.intensity = intensity
        self.frameRate = frameRate
        self.staticPhase = staticPhase
        self.reduceMotion = reduceMotion
        self.pausesWhenInactive = pausesWhenInactive
    }

    /// The reference animation.
    public static let `default` = AnimationConfiguration()

    /// A still image of ``staticPhase``, with no animation.
    public static let `static` = AnimationConfiguration(isEnabled: false)
}

/// How the background responds to the Reduce Motion accessibility setting.
public enum ReduceMotionPolicy: Hashable, Sendable {
    /// Shows a still image when the person has turned on Reduce Motion. The default.
    case followsSystem
    /// Always shows a still image, as if Reduce Motion were on.
    ///
    /// Useful when your app has its own motion setting, and to preview what people with Reduce Motion see.
    case always
    /// Keeps animating, even when Reduce Motion is on.
    ///
    /// Only use this if your app offers its own way to turn the animation off.
    case never

    /// Whether motion should be reduced, given the system setting.
    func reducesMotion(systemSetting: Bool) -> Bool {
        switch self {
        case .followsSystem: systemSetting
        case .always: true
        case .never: false
        }
    }
}

// MARK: - Resolved values

extension AnimationConfiguration {
    static let cycleDurationRange: ClosedRange<Double> = 1...3_600
    static let speedRange: ClosedRange<Double> = 0...20
    static let intensityRange: ClosedRange<Double> = 0...2
    static let frameRateRange: ClosedRange<Double> = 1...120

    /// ``cycleDuration``, clamped to its range.
    var resolvedCycleDuration: TimeInterval {
        cycleDuration.sanitized(in: Self.cycleDurationRange, fallback: Self.default.cycleDuration)
    }

    /// ``speed``, clamped to its range.
    var resolvedSpeed: Double {
        speed.sanitized(in: Self.speedRange, fallback: Self.default.speed)
    }

    /// ``intensity``, clamped to its range.
    var resolvedIntensity: Double {
        intensity.sanitized(in: Self.intensityRange, fallback: Self.default.intensity)
    }

    /// ``frameRate``, clamped to its range.
    var resolvedFrameRate: Double {
        frameRate.sanitized(in: Self.frameRateRange, fallback: Self.default.frameRate)
    }

    /// The shortest time between two frames.
    var frameInterval: TimeInterval { 1 / resolvedFrameRate }

    /// How many cycles pass each second at the configured speed.
    var cyclesPerSecond: Double {
        Self.cyclesPerSecond(cycleDuration: cycleDuration, speed: speed)
    }

    static func cyclesPerSecond(cycleDuration: TimeInterval, speed: Double) -> Double {
        let duration = cycleDuration.sanitized(in: cycleDurationRange, fallback: Self.default.cycleDuration)
        let speed = speed.sanitized(in: speedRange, fallback: Self.default.speed)
        return speed / duration
    }
}
