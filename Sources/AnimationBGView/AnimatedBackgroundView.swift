import SwiftUI

/// A soft, slowly moving pale-yellow background with a large V.
///
/// Four soft lights, green-yellow, golden, peach, and tan, circle behind a translucent V, completing
/// one turn about every 51 seconds. Everything is drawn with SwiftUI, with no images or video.
///
/// Put it behind your content:
///
/// ```swift
/// ZStack {
///     AnimatedBackgroundView()
///     Text("Welcome")
/// }
/// ```
///
/// The background fills whatever space it's given and, by default, extends under the safe areas. It
/// pauses while its scene isn't active, shows a still image when Reduce Motion is on, and is hidden
/// from VoiceOver.
public struct AnimatedBackgroundView: View {
    private let configuration: AnimatedBackgroundConfiguration

    @Environment(\.accessibilityReduceMotion) private var systemReducesMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var timeline: AnimationTimeline
    /// Outside a scene, `scenePhase` stays at its default, `.background`, so it's only trusted once
    /// the view has seen it become `.active`. Otherwise a host that never sets it would never animate.
    @State private var hasSeenActiveScene = false

    /// Creates the background.
    ///
    /// - Parameter configuration: How the background looks and moves. The default reproduces the reference.
    public init(configuration: AnimatedBackgroundConfiguration = .default) {
        self.configuration = configuration
        _timeline = State(initialValue: AnimationTimeline(
            start: configuration.motion.staticPhase,
            rate: configuration.motion.cyclesPerSecond,
            date: Date()
        ))
    }

    public var body: some View {
        let mode = playbackMode
        ZStack {
            AnimatedGradientView(configuration: configuration, mode: mode, timeline: timeline)
            if configuration.vShape.isVisible {
                VShapeLayer(vShape: configuration.vShape, color: configuration.palette.vShape, scaling: configuration.scaling)
                    .equatable()
            }
        }
        .ignoresSafeArea(configuration.ignoresSafeArea ? .all : [], edges: .all)
        .accessibilityHidden(true)
        .task(id: scenePhase) {
            if scenePhase == .active { hasSeenActiveScene = true }
        }
        .task(id: ClockInput(mode: mode, rate: configuration.motion.cyclesPerSecond, stillPhase: configuration.motion.staticPhase)) {
            timeline.update(
                mode: mode,
                rate: configuration.motion.cyclesPerSecond,
                stillPhase: configuration.motion.staticPhase,
                at: Date()
            )
        }
    }

    private var playbackMode: PlaybackMode {
        PlaybackMode(
            motion: configuration.motion,
            systemReducesMotion: systemReducesMotion,
            sceneIsActive: scenePhase == .active || !hasSeenActiveScene
        )
    }
}

/// What the clock needs to react to.
private struct ClockInput: Equatable {
    let mode: PlaybackMode
    let rate: Double
    let stillPhase: AnimationPhase
}

#Preview("Default") {
    AnimatedBackgroundView()
}

#Preview("Still image") {
    AnimatedBackgroundView(configuration: .static)
}
