import SwiftUI

/// The soft coloured lights that move behind the V.
///
/// Each light is a round glow that fades out smoothly from its centre, and travels along its own
/// ellipse. The defaults are the four lights measured from the reference: green-yellow, golden,
/// peach, and tan, all moving counter-clockwise.
///
/// ```swift
/// var configuration = AnimatedBackgroundConfiguration()
/// configuration.gradient.intensity = 0.6    // Softer colours.
/// configuration.gradient.softness = 1.3     // Larger, more diffuse glows.
/// ```
public struct GradientConfiguration: Equatable, Sendable {
    /// The lights, drawn in order. Light `n` takes its colour from ``BackgroundColorPalette/lights``.
    public var lights: [GradientLight]

    /// How strong the colours are, as a multiplier of each light's ``GradientLight/peakOpacity``.
    /// From 0 to 2; the default is 1.
    ///
    /// The result is limited to full opacity. `0` leaves only the base colour and the V.
    public var intensity: Double

    /// How large and diffuse the glows are, as a multiplier of each light's ``GradientLight/size``.
    /// From 0.25 to 3; the default is 1.
    public var softness: Double

    /// Creates a gradient configuration. Every parameter has a default that matches the reference.
    public init(lights: [GradientLight] = GradientLight.reference, intensity: Double = 1, softness: Double = 1) {
        self.lights = lights
        self.intensity = intensity
        self.softness = softness
    }

    /// The reference lights.
    public static let `default` = GradientConfiguration()

    static let intensityRange: ClosedRange<Double> = 0...2
    static let softnessRange: ClosedRange<Double> = 0.25...3

    var resolvedIntensity: Double {
        intensity.sanitized(in: Self.intensityRange, fallback: Self.default.intensity)
    }

    var resolvedSoftness: Double {
        softness.sanitized(in: Self.softnessRange, fallback: Self.default.softness)
    }
}

/// One soft coloured light, and the ellipse it travels along.
///
/// Positions and sizes are in *design units*: fractions of the composition's width, measured from its
/// top-left corner, with y increasing downward. On a phone in portrait the composition is as wide as
/// the screen, so `CGPoint(x: 0.5, y: 0.5)` is halfway across and half a screen-width down.
public struct GradientLight: Equatable, Sendable {
    /// The centre of the ellipse the light travels along, in design units.
    public var orbitCenter: CGPoint

    /// The horizontal and vertical radii of the ellipse, in design units. Zero keeps the light still.
    public var orbitRadii: CGSize

    /// Where on the ellipse the light is at phase `0`, measured clockwise from the three o'clock position.
    public var startAngle: Angle

    /// Whole turns per cycle. Positive values move counter-clockwise, as in the reference; negative
    /// values move clockwise; zero keeps the light still.
    ///
    /// A whole number of turns brings every light back to its start at the end of the cycle,
    /// which is what makes the loop seamless.
    public var revolutions: Int

    /// The radius at which the glow has faded to 61% of its peak: the standard deviation of a
    /// Gaussian, in design units. The glow fades to nothing at three times this distance.
    public var size: Double

    /// The light's opacity at its centre, from 0 to 1.
    public var peakOpacity: Double

    /// Creates a light.
    public init(
        orbitCenter: CGPoint,
        orbitRadii: CGSize,
        startAngle: Angle,
        revolutions: Int = 1,
        size: Double,
        peakOpacity: Double
    ) {
        self.orbitCenter = orbitCenter
        self.orbitRadii = orbitRadii
        self.startAngle = startAngle
        self.revolutions = revolutions
        self.size = size
        self.peakOpacity = peakOpacity
    }

    /// The light's centre at a phase, in design units.
    ///
    /// - Parameters:
    ///   - phase: The position in the cycle.
    ///   - travel: A multiplier for the ellipse's radii. `1` is the configured path.
    public func center(at phase: AnimationPhase, travel: Double = 1) -> CGPoint {
        let travel = travel.sanitized(in: AnimationConfiguration.intensityRange, fallback: 1)
        let startRadians = startAngle.radians.isFinite ? startAngle.radians : 0
        // The y axis points down, so a decreasing angle moves counter-clockwise on screen.
        let angle = startRadians - phase.radians * Double(revolutions)
        let centerX = Double(orbitCenter.x).sanitized(in: -10...10, fallback: 0.5)
        let centerY = Double(orbitCenter.y).sanitized(in: -10...10, fallback: 0.5)
        let radiusX = Double(orbitRadii.width).sanitized(in: 0...10, fallback: 0) * travel
        let radiusY = Double(orbitRadii.height).sanitized(in: 0...10, fallback: 0) * travel
        return CGPoint(x: centerX + radiusX * cos(angle), y: centerY + radiusY * sin(angle))
    }
}

extension GradientLight {
    /// The green-yellow light.
    public static let referenceGreenYellow = GradientLight(
        orbitCenter: CGPoint(x: 0.721, y: 0.435),
        orbitRadii: CGSize(width: 0.204, height: 0.121),
        startAngle: .degrees(-156.6),
        size: 0.175,
        peakOpacity: 0.8
    )

    /// The golden light.
    public static let referenceGolden = GradientLight(
        orbitCenter: CGPoint(x: 0.679, y: 0.377),
        orbitRadii: CGSize(width: 0.253, height: 0.156),
        startAngle: .degrees(-27.3),
        size: 0.162,
        peakOpacity: 0.8
    )

    /// The peach light.
    public static let referencePeach = GradientLight(
        orbitCenter: CGPoint(x: 0.761, y: 0.498),
        orbitRadii: CGSize(width: 0.213, height: 0.123),
        startAngle: .degrees(75.9),
        size: 0.127,
        peakOpacity: 0.8
    )

    /// The tan light.
    public static let referenceTan = GradientLight(
        orbitCenter: CGPoint(x: 0.591, y: 0.385),
        orbitRadii: CGSize(width: 0.187, height: 0.150),
        startAngle: .degrees(101.0),
        size: 0.172,
        peakOpacity: 0.8
    )

    /// The four lights measured from the reference, in the order of ``BackgroundColorPalette/reference``.
    ///
    /// They circle the middle of the V counter-clockwise, one turn per cycle. At phase `0` they're
    /// arranged as in the reference colour image.
    public static let reference: [GradientLight] = [referenceGreenYellow, referenceGolden, referencePeach, referenceTan]
}
