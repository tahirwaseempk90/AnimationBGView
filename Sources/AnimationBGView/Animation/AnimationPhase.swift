import Foundation

/// A position within one animation cycle.
///
/// A phase is a fraction from `0` up to, but not including, `1`. Values outside that range wrap
/// around, so `1.25` and `-0.75` both become `0.25`. Phase `0` and phase `1` are the same moment,
/// which is what makes the loop seamless: every moving part returns to where it started.
///
/// ```swift
/// var configuration = AnimatedBackgroundConfiguration.static
/// configuration.motion.staticPhase = 0.25   // A quarter of the way through the cycle.
/// ```
public struct AnimationPhase: Hashable, Sendable, CustomStringConvertible {
    /// The position within the cycle, from `0` up to, but not including, `1`.
    public let fraction: Double

    /// Creates a phase, wrapping the value into `0..<1`.
    ///
    /// A non-finite value becomes `0`.
    public init(_ fraction: Double) {
        guard fraction.isFinite else {
            self.fraction = 0
            return
        }
        let wrapped = fraction - fraction.rounded(.down)
        // For tiny negative values, `fraction - floor(fraction)` rounds to exactly 1.
        self.fraction = wrapped < 1 ? wrapped : 0
    }

    /// The start of the cycle.
    public static let zero = AnimationPhase(0)

    /// The phase as an angle in radians, from `0` up to `2π`.
    public var radians: Double { fraction * 2 * .pi }

    /// The phase after moving forward by a number of cycles, which may be fractional or negative.
    public func advanced(by cycles: Double) -> AnimationPhase {
        AnimationPhase(fraction + cycles)
    }

    /// The phase reached after a period of time.
    ///
    /// - Parameters:
    ///   - seconds: The time that has passed.
    ///   - cycleDuration: How long one cycle takes at normal speed, in seconds.
    ///   - speed: A multiplier for the playback rate.
    ///   - start: The phase at time zero.
    public static func elapsed(
        _ seconds: TimeInterval,
        cycleDuration: TimeInterval,
        speed: Double = 1,
        from start: AnimationPhase = .zero
    ) -> AnimationPhase {
        let rate = AnimationConfiguration.cyclesPerSecond(cycleDuration: cycleDuration, speed: speed)
        let cycles = seconds.isFinite ? seconds * rate : 0
        return start.advanced(by: cycles)
    }

    public var description: String { "AnimationPhase(\(fraction))" }
}

extension AnimationPhase: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnimationPhase: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(Double(value))
    }
}
