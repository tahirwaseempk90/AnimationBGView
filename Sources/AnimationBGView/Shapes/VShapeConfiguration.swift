import CoreGraphics

/// The large V drawn over the lights.
///
/// The V is filled with ``BackgroundColorPalette/vShape``, the base colour by default, at
/// ``opacity``, so the lights show through it softly. It doesn't move.
///
/// ```swift
/// var configuration = AnimatedBackgroundConfiguration()
/// configuration.vShape.opacity = 0.4     // A fainter V.
/// configuration.vShape.isVisible = false // No V at all.
/// ```
public struct VShapeConfiguration: Equatable, Sendable {
    /// Whether the V is drawn. The default is `true`.
    public var isVisible: Bool

    /// The opacity of the V's fill. From 0 to 1; the default, 0.58, was measured from the reference.
    public var opacity: Double

    /// The V's size, as a multiplier, around its middle. From 0.25 to 3; the default is 1.
    ///
    /// The strokes always run off the top edge, whatever the scale.
    public var scale: Double

    /// How soft the V's edges are: the width of the fade across each edge, as a fraction of the
    /// composition's width. From 0 to 0.1; the default, 0.0115, matches the reference, where it's
    /// about 4.5 points on a phone. `0` gives crisp, antialiased edges.
    public var edgeSoftness: Double

    /// The V's proportions and position.
    public var geometry: VShapeGeometry

    /// Creates a V configuration. Every parameter has a default that matches the reference.
    public init(
        isVisible: Bool = true,
        opacity: Double = 0.58,
        scale: Double = 1,
        edgeSoftness: Double = 0.0115,
        geometry: VShapeGeometry = .reference
    ) {
        self.isVisible = isVisible
        self.opacity = opacity
        self.scale = scale
        self.edgeSoftness = edgeSoftness
        self.geometry = geometry
    }

    /// The reference V.
    public static let `default` = VShapeConfiguration()

    /// No V.
    public static let hidden = VShapeConfiguration(isVisible: false)

    static let opacityRange: ClosedRange<Double> = 0...1
    static let scaleRange: ClosedRange<Double> = 0.25...3
    static let edgeSoftnessRange: ClosedRange<Double> = 0...0.1

    var resolvedOpacity: Double { opacity.sanitized(in: Self.opacityRange, fallback: Self.default.opacity) }
    var resolvedScale: Double { scale.sanitized(in: Self.scaleRange, fallback: Self.default.scale) }
    var resolvedEdgeSoftness: Double {
        edgeSoftness.sanitized(in: Self.edgeSoftnessRange, fallback: Self.default.edgeSoftness)
    }
}

/// The proportions and position of the V, in design units.
///
/// Design units are fractions of the composition's width, measured from its top-left corner, with y
/// increasing downward. Each of the V's four straight edges is described by where it crosses the
/// top edge, `y = 0`, and the point where it meets its partner:
///
/// ```text
/// outerLeftTop   innerLeftTop   innerRightTop   outerRightTop
///      ╲              ╲               ╱               ╱
///        ╲              ╲           ╱               ╱
///          ╲              ╲       ╱               ╱
///            ╲              ╲   ╱               ╱
///              ╲          notch apex          ╱
///                ╲                          ╱
///                  ╲                      ╱
///                    ╲                  ╱
///                      ╲              ╱
///                        ╲          ╱
///                          ╲      ╱
///                            ╲  ╱
///                           vertex
/// ```
///
/// The reference has a thick left stroke and a thin right one, like the letter V in many typefaces,
/// and sits right of centre.
public struct VShapeGeometry: Equatable, Sendable {
    /// Where the left stroke's outer edge crosses the top edge.
    public var outerLeftTop: Double
    /// Where the left stroke's inner edge crosses the top edge.
    public var innerLeftTop: Double
    /// Where the right stroke's inner edge crosses the top edge.
    public var innerRightTop: Double
    /// Where the right stroke's outer edge crosses the top edge.
    public var outerRightTop: Double
    /// The bottom point of the V, where the two outer edges meet.
    public var vertex: CGPoint
    /// The bottom of the notch between the strokes, where the two inner edges meet.
    public var notchApex: CGPoint

    /// Creates a V from its four top crossings, its vertex, and its notch apex, in design units.
    public init(
        outerLeftTop: Double,
        innerLeftTop: Double,
        innerRightTop: Double,
        outerRightTop: Double,
        vertex: CGPoint,
        notchApex: CGPoint
    ) {
        self.outerLeftTop = outerLeftTop
        self.innerLeftTop = innerLeftTop
        self.innerRightTop = innerRightTop
        self.outerRightTop = outerRightTop
        self.vertex = vertex
        self.notchApex = notchApex
    }

    /// The V measured from the reference images.
    ///
    /// Its edges lean 20.0°, 19.1°, 16.5°, and 18.7° from vertical, from left to right. Its
    /// notch apex is at 69% of the width, and its vertex at 64%, 1.07 widths down, which is about
    /// halfway down a phone in portrait.
    public static let reference = VShapeGeometry(
        outerLeftTop: 0.2497,
        innerLeftTop: 0.4896,
        innerRightTop: 0.8587,
        outerRightTop: 0.9981,
        vertex: CGPoint(x: 0.6372, y: 1.0676),
        notchApex: CGPoint(x: 0.6882, y: 0.5740)
    )

    /// Whether the values describe a drawable V.
    ///
    /// All values must be finite, the four top crossings must be in order from left to right, the
    /// vertex and the notch apex must be below the top edge, the notch apex must be above the vertex,
    /// and the notch must lie inside the V. An invalid V isn't drawn.
    public var isValid: Bool {
        let values = [outerLeftTop, innerLeftTop, innerRightTop, outerRightTop,
                      Double(vertex.x), Double(vertex.y), Double(notchApex.x), Double(notchApex.y)]
        guard values.allSatisfy(\.isFinite) else { return false }
        guard outerLeftTop < innerLeftTop, innerLeftTop < innerRightTop, innerRightTop < outerRightTop else {
            return false
        }
        guard notchApex.y > 0, vertex.y > notchApex.y else { return false }
        // The notch apex must be strictly inside the outer triangle.
        let outline = VShapeOutline(geometry: self)
        let apexV = Double(notchApex.y)
        return outline.outerLeft.u(at: apexV) < Double(notchApex.x)
            && Double(notchApex.x) < outline.outerRight.u(at: apexV)
    }
}
