import SwiftUI

/// Draws the V once, in its own layer.
///
/// The V never moves, so it lives outside the `TimelineView`. SwiftUI only redraws it when its
/// configuration or size changes, not on every frame of the animation beneath it.
struct VShapeLayer: View, Equatable {
    let vShape: VShapeConfiguration
    let color: Color
    let scaling: CompositionScaling

    var body: some View {
        Canvas { context, size in
            VShapeRenderer.draw(in: &context, size: size, vShape: vShape, color: color, scaling: scaling)
        }
    }
}

/// Draws the V with softened edges.
///
/// A Gaussian blur of a whole-screen layer would cost an offscreen pass. Instead, the polygon is
/// filled a few times, each copy offset a little along every edge's normal, from slightly inside to
/// slightly outside. The copies are nested, so a point near an edge is covered by only the larger
/// ones. Their opacities are chosen so the coverage rises in equal steps, reaching exactly the
/// configured opacity in the middle, which gives a straight ramp across each edge at any opacity.
enum VShapeRenderer {
    /// The number of copies drawn when the edges are soft.
    static let featherLayerCount = 4

    struct Layer: Equatable {
        /// How far each edge moves outward, in design units. Negative values move it inward.
        let expansion: Double
        /// The opacity of this copy.
        let opacity: Double
    }

    /// The copies to draw for a configuration, from the smallest to the largest.
    static func layers(for vShape: VShapeConfiguration) -> [Layer] {
        let opacity = vShape.resolvedOpacity
        let softness = vShape.resolvedEdgeSoftness
        guard opacity > 0 else { return [] }
        guard softness > 0 else { return [Layer(expansion: 0, opacity: opacity)] }
        let count = Double(featherLayerCount)
        return (0..<featherLayerCount).map { index in
            // Spread from −softness/2 to +softness/2, so the ramp is `softness` wide.
            let position = Double(index) / (count - 1) - 0.5
            // A point just inside this copy's edge is covered by it and every larger copy: `rank`
            // copies in all. Same-coloured copies composited "over" each other combine to
            // 1 − ∏(1 − aᵢ), so this opacity brings the coverage from `opacity · (rank − 1) / count`
            // up to `opacity · rank / count`.
            let rank = count - Double(index)
            let before = 1 - opacity * (rank - 1) / count
            let after = 1 - opacity * rank / count
            let layerOpacity = before > 0 ? 1 - after / before : 1
            return Layer(expansion: position * softness, opacity: layerOpacity)
        }
    }

    static func draw(
        in context: inout GraphicsContext,
        size: CGSize,
        vShape: VShapeConfiguration,
        color: Color,
        scaling: CompositionScaling
    ) {
        guard vShape.isVisible, vShape.geometry.isValid else { return }
        let layout = CompositionLayout(size: size, scaling: scaling)
        guard layout.unit > 0 else { return }
        let outline = VShapeOutline(geometry: vShape.geometry).scaled(by: vShape.resolvedScale)
        for layer in layers(for: vShape) {
            let path = outline.expanded(by: layer.expansion).path(unit: layout.unit, origin: layout.origin)
            context.fill(path, with: .color(color.opacity(layer.opacity)))
        }
    }
}
