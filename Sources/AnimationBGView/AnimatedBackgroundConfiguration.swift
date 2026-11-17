import SwiftUI

/// Everything that describes an ``AnimatedBackgroundView``.
///
/// Start from ``default``, which reproduces the reference animation, and change only what you need:
///
/// ```swift
/// var configuration = AnimatedBackgroundConfiguration.default
/// configuration.motion.speed = 1.5
/// configuration.gradient.intensity = 0.7
/// configuration.vShape.opacity = 0.45
///
/// AnimatedBackgroundView(configuration: configuration)
/// ```
///
/// Every part is a plain value type, so configurations can be stored, compared, and passed around.
public struct AnimatedBackgroundConfiguration: Equatable, Sendable {
    /// The colours.
    public var palette: BackgroundColorPalette

    /// How the background moves.
    public var motion: AnimationConfiguration

    /// The V.
    public var vShape: VShapeConfiguration

    /// The moving lights.
    public var gradient: GradientConfiguration

    /// How the composition is sized to the view. The default, ``CompositionScaling/fit``, keeps the
    /// whole V in view on short, wide screens.
    public var scaling: CompositionScaling

    /// Whether the background extends under the safe areas, such as the status bar and the home
    /// indicator. The default is `true`, which is what a full-screen background needs.
    ///
    /// Set it to `false` to keep the background strictly inside its frame, for example in a card.
    public var ignoresSafeArea: Bool

    /// Creates a configuration. Every parameter has a default that matches the reference.
    public init(
        palette: BackgroundColorPalette = .reference,
        motion: AnimationConfiguration = .default,
        vShape: VShapeConfiguration = .default,
        gradient: GradientConfiguration = .default,
        scaling: CompositionScaling = .fit,
        ignoresSafeArea: Bool = true
    ) {
        self.palette = palette
        self.motion = motion
        self.vShape = vShape
        self.gradient = gradient
        self.scaling = scaling
        self.ignoresSafeArea = ignoresSafeArea
    }

    /// The reference animation.
    public static let `default` = AnimatedBackgroundConfiguration()

    /// The reference background as a still image, at ``AnimationConfiguration/staticPhase``.
    public static let `static` = AnimatedBackgroundConfiguration(motion: .static)
}
