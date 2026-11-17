import CoreGraphics

/// How the composition (the V and the lights) is sized to the view.
public enum CompositionScaling: Hashable, Sendable {
    /// Matches the view's width, but shrinks on short, wide views so that the whole V stays in view.
    /// The default.
    ///
    /// On a phone in portrait, and on an iPad, the composition is as wide as the view. When the view
    /// is shorter than 1.2 times its width, the composition shrinks to fit the height and is centred
    /// horizontally.
    case fit

    /// Always matches the view's width. On short, wide views the bottom of the V extends past the
    /// bottom edge, and only its upper part shows.
    case fillWidth
}

/// Converts design units, fractions of the composition's width, to points in the view.
///
/// The composition is anchored to the top of the view, because the V runs off the top edge.
struct CompositionLayout: Equatable, Sendable {
    /// The composition's height in design units: the bottom of the V, 1.07, plus a margin.
    static let compositionHeight: CGFloat = 1.2

    /// Points per design unit: the composition's width in points.
    let unit: CGFloat
    /// The composition's top-left corner in the view.
    let origin: CGPoint

    init(size: CGSize, scaling: CompositionScaling) {
        let width = size.width.isFinite ? max(0, size.width) : 0
        let height = size.height.isFinite ? max(0, size.height) : 0
        switch scaling {
        case .fit:
            unit = min(width, height / Self.compositionHeight)
        case .fillWidth:
            unit = width
        }
        origin = CGPoint(x: (width - unit) / 2, y: 0)
    }

    /// The composition's frame in the view.
    var compositionRect: CGRect {
        CGRect(x: origin.x, y: origin.y, width: unit, height: unit * Self.compositionHeight)
    }

    /// A point in design units, converted to the view.
    func point(_ designPoint: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + designPoint.x * unit, y: origin.y + designPoint.y * unit)
    }

    /// A length in design units, converted to points.
    func length(_ designLength: Double) -> CGFloat {
        CGFloat(designLength) * unit
    }
}
