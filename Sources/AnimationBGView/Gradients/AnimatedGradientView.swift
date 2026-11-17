import SwiftUI

/// The base colour and the moving lights: the only part of the background that changes over time.
///
/// `TimelineView` asks for a new frame at most ``AnimationConfiguration/frameRate`` times a second,
/// and stops asking while paused. Each frame is one `Canvas` pass: a fill and four gradients.
struct AnimatedGradientView: View {
    let configuration: AnimatedBackgroundConfiguration
    let mode: PlaybackMode
    let timeline: AnimationTimeline

    var body: some View {
        TimelineView(.animation(minimumInterval: configuration.motion.frameInterval, paused: mode != .running)) { context in
            let phase = displayedPhase(at: context.date)
            Canvas { graphics, size in
                ColorFieldRenderer.draw(in: &graphics, size: size, phase: phase, configuration: configuration)
            }
        }
    }

    func displayedPhase(at date: Date) -> AnimationPhase {
        mode == .still ? configuration.motion.staticPhase : timeline.phase(at: date)
    }
}
