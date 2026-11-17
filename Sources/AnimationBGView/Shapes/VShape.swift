import SwiftUI

/// The V from the background, as a reusable shape.
///
/// The rectangle's width is one design unit, so the V keeps its proportions in any frame. Its strokes
/// always run up to the rectangle's top edge, and its bottom point is `geometry.vertex.y` widths
/// below the top, so it can extend below a short rectangle.
///
/// ```swift
/// VShape()
///     .fill(.white.opacity(0.5))
///     .frame(width: 300, height: 360)
/// ```
///
/// `scale` is animatable:
///
/// ```swift
/// VShape(scale: isLarge ? 1.2 : 1)
///     .fill(.yellow)
///     .animation(.spring, value: isLarge)
/// ```
public struct VShape: Shape {
    /// The V's proportions and position, in design units.
    public var geometry: VShapeGeometry

    /// The V's size, as a multiplier, around its middle. From 0.25 to 3.
    public var scale: Double

    /// Creates the V.
    public init(geometry: VShapeGeometry = .reference, scale: Double = 1) {
        self.geometry = geometry
        self.scale = scale
    }

    public var animatableData: Double {
        get { scale }
        set { scale = newValue }
    }

    public func path(in rect: CGRect) -> Path {
        let rect = rect.standardized
        guard geometry.isValid, !rect.isNull, !rect.isInfinite,
              rect.width.isFinite, rect.width > 0, rect.minX.isFinite, rect.minY.isFinite else {
            return Path()
        }
        let factor = scale.sanitized(in: VShapeConfiguration.scaleRange, fallback: 1)
        return VShapeOutline(geometry: geometry).scaled(by: factor).path(unit: rect.width, origin: rect.origin)
    }

    /// The V doesn't mirror in right-to-left layouts: its thick stroke stays on the left, as in the reference.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public var layoutDirectionBehavior: LayoutDirectionBehavior { .fixed }
}
