import SwiftUI

/// Draws the base colour and the moving lights for one frame.
///
/// The work is split in two: ``resolvedLights(phase:size:configuration:)`` is a pure calculation
/// from a phase and a size to where every light is and how it looks, which the tests check
/// directly, and ``draw(in:size:phase:configuration:)`` turns that into four gradient fills.
enum ColorFieldRenderer {
    /// A light, ready to draw.
    struct ResolvedLight: Equatable {
        /// The light's centre, in points.
        let center: CGPoint
        /// The distance at which the glow reaches zero, in points.
        let radius: CGFloat
        /// The light's colour.
        let color: Color
        /// The opacity at the light's centre.
        let opacity: Double
    }

    /// Every visible light at a phase, in drawing order.
    static func resolvedLights(
        phase: AnimationPhase,
        size: CGSize,
        configuration: AnimatedBackgroundConfiguration
    ) -> [ResolvedLight] {
        let layout = CompositionLayout(size: size, scaling: configuration.scaling)
        guard layout.unit > 0 else { return [] }
        let gradient = configuration.gradient
        let travel = configuration.motion.resolvedIntensity
        return gradient.lights.enumerated().compactMap { index, light in
            guard let color = configuration.palette.lightColor(at: index) else { return nil }
            let opacity = min(1, light.peakOpacity.sanitized(in: 0...1, fallback: 0) * gradient.resolvedIntensity)
            let sigma = light.size.sanitized(in: 0...2, fallback: 0) * gradient.resolvedSoftness
            let radius = layout.length(sigma * GaussianFalloff.cutoff)
            guard opacity > 0, radius > 0 else { return nil }
            return ResolvedLight(
                center: layout.point(light.center(at: phase, travel: travel)),
                radius: radius,
                color: color,
                opacity: opacity
            )
        }
    }

    static func draw(
        in context: inout GraphicsContext,
        size: CGSize,
        phase: AnimationPhase,
        configuration: AnimatedBackgroundConfiguration
    ) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(configuration.palette.base))
        for light in resolvedLights(phase: phase, size: size, configuration: configuration) {
            let bounds = CGRect(
                x: light.center.x - light.radius,
                y: light.center.y - light.radius,
                width: light.radius * 2,
                height: light.radius * 2
            )
            context.fill(
                Path(ellipseIn: bounds),
                with: .radialGradient(
                    GaussianFalloff.gradient(color: light.color, peakOpacity: light.opacity),
                    center: light.center,
                    startRadius: 0,
                    endRadius: light.radius
                )
            )
        }
    }
}

/// The soft round falloff of each light: a Gaussian, sampled into gradient stops.
enum GaussianFalloff {
    /// Where the glow is cut off, in standard deviations. At 3, a Gaussian is down to 1.1%.
    static let cutoff: Double = 3

    /// The number of gradient stops. Twelve keeps the straight segments between them within 1% of the curve.
    static let stopCount = 12

    /// Each stop's position along the radius, from 0 to 1, and its opacity relative to the peak.
    ///
    /// The curve is shifted and rescaled to reach exactly zero at the cutoff, so a light has no visible edge.
    static let stops: [(location: Double, opacity: Double)] = {
        let floor = exp(-0.5 * cutoff * cutoff)
        return (0..<stopCount).map { index in
            let location = Double(index) / Double(stopCount - 1)
            let distance = location * cutoff
            let value = (exp(-0.5 * distance * distance) - floor) / (1 - floor)
            return (location, max(0, value))
        }
    }()

    /// The relative opacity at a distance from the centre, in standard deviations, as drawn: the
    /// straight-line interpolation between stops that the gradient uses.
    static func relativeOpacity(atDistance distance: Double) -> Double {
        guard distance.isFinite else { return 0 }
        let location = max(0, distance) / cutoff
        guard location < 1 else { return 0 }
        let scaled = location * Double(stopCount - 1)
        let lower = Int(scaled)
        let fraction = scaled - Double(lower)
        return stops[lower].opacity * (1 - fraction) + stops[lower + 1].opacity * fraction
    }

    static func gradient(color: Color, peakOpacity: Double) -> Gradient {
        Gradient(stops: stops.map { Gradient.Stop(color: color.opacity(peakOpacity * $0.opacity), location: $0.location) })
    }
}
