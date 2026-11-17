import Foundation

/// Whether the background is moving, holding a frame, or showing its still image.
enum PlaybackMode: Hashable, Sendable {
    /// Moving.
    case running
    /// Holding the current frame, for example while the scene is inactive.
    case paused
    /// Showing ``AnimationConfiguration/staticPhase``: animation is off, or motion is reduced.
    case still

    init(motion: AnimationConfiguration, systemReducesMotion: Bool, sceneIsActive: Bool) {
        if !motion.isEnabled || motion.reduceMotion.reducesMotion(systemSetting: systemReducesMotion) {
            self = .still
        } else if motion.pausesWhenInactive && !sceneIsActive {
            self = .paused
        } else {
            self = .running
        }
    }
}

/// Maps dates to phases, and keeps the phase continuous when the animation pauses, resumes, or
/// changes speed.
///
/// A phase computed straight from the clock, `date × rate`, jumps whenever the rate changes, because
/// the whole elapsed time is suddenly multiplied by a different number. This clock instead remembers
/// an anchor, a date and the phase at that date, and moves the anchor whenever anything changes. So
/// the frame just after a change is always the frame just before it.
struct AnimationTimeline: Equatable, Sendable {
    /// The date of the last change.
    private(set) var anchorDate: Date
    /// The phase at ``anchorDate``, in cycles, kept within `0..<1`.
    private(set) var anchorCycles: Double
    /// Cycles per second while running.
    private(set) var rate: Double
    /// Whether the phase advances with time.
    private(set) var isRunning: Bool

    init(start: AnimationPhase, rate: Double, date: Date, isRunning: Bool = true) {
        anchorDate = date
        anchorCycles = start.fraction
        self.rate = Self.sanitizedRate(rate)
        self.isRunning = isRunning
    }

    /// The phase at a date.
    ///
    /// Dates before the anchor give the anchor's phase, so the animation never runs backwards if the
    /// clock does.
    func phase(at date: Date) -> AnimationPhase {
        guard isRunning else { return AnimationPhase(anchorCycles) }
        let elapsed = max(0, date.timeIntervalSince(anchorDate))
        return AnimationPhase(anchorCycles + elapsed * rate)
    }

    /// Changes the rate, continuing from the current phase.
    mutating func setRate(_ newRate: Double, at date: Date) {
        let newRate = Self.sanitizedRate(newRate)
        guard newRate != rate else { return }
        reanchor(at: date)
        rate = newRate
    }

    /// Holds the current phase.
    mutating func pause(at date: Date) {
        guard isRunning else { return }
        reanchor(at: date)
        isRunning = false
    }

    /// Starts advancing again from the held phase.
    mutating func resume(at date: Date) {
        guard !isRunning else { return }
        anchorDate = date
        isRunning = true
    }

    /// Moves to a phase, keeping the running state.
    mutating func jump(to phase: AnimationPhase, at date: Date) {
        anchorDate = date
        anchorCycles = phase.fraction
    }

    /// Brings the clock in line with what the view is showing.
    ///
    /// While the still image is showing, the clock holds that frame, so that turning the animation
    /// back on continues from the image instead of jumping to wherever the clock would have been.
    mutating func update(mode: PlaybackMode, rate newRate: Double, stillPhase: AnimationPhase, at date: Date) {
        setRate(newRate, at: date)
        switch mode {
        case .running:
            resume(at: date)
        case .paused:
            pause(at: date)
        case .still:
            pause(at: date)
            jump(to: stillPhase, at: date)
        }
    }

    private mutating func reanchor(at date: Date) {
        anchorCycles = phase(at: date).fraction
        anchorDate = date
    }

    private static func sanitizedRate(_ rate: Double) -> Double {
        rate.isFinite ? max(0, rate) : 0
    }
}
