import SwiftUI

/// The V as four straight lines in design units, and the polygon they enclose.
///
/// Each line is `u = slope · v + intercept`, where `u` is across and `v` is down, both in design
/// units. Working with lines rather than corner points makes the two operations the V needs exact
/// and cheap: scaling around a point, and offsetting every edge along its normal to soften it.
struct VShapeOutline: Equatable, Sendable {
    struct Line: Equatable, Sendable {
        var slope: Double
        var intercept: Double

        /// The line through two points.
        init(through first: CGPoint, _ second: CGPoint) {
            let deltaV = Double(second.y - first.y)
            slope = deltaV == 0 ? 0 : Double(second.x - first.x) / deltaV
            intercept = Double(first.x) - slope * Double(first.y)
        }

        init(slope: Double, intercept: Double) {
            self.slope = slope
            self.intercept = intercept
        }

        /// The horizontal position of the line at a height.
        func u(at v: Double) -> Double { slope * v + intercept }

        /// The line moved by a distance along its normal. Positive distances move it toward +u.
        func offset(by distance: Double) -> Line {
            Line(slope: slope, intercept: intercept + distance * (1 + slope * slope).squareRoot())
        }

        /// The line scaled by a factor around an anchor. Scaling doesn't change a line's slope.
        func scaled(by factor: Double, around anchor: CGPoint) -> Line {
            let anchorU = Double(anchor.x)
            let anchorV = Double(anchor.y)
            return Line(slope: slope, intercept: factor * intercept + (1 - factor) * (anchorU - slope * anchorV))
        }

        /// Where two lines cross, or `nil` if they're parallel.
        func intersection(with other: Line) -> CGPoint? {
            let slopeDifference = slope - other.slope
            guard abs(slopeDifference) > 1e-12 else { return nil }
            let v = (other.intercept - intercept) / slopeDifference
            return CGPoint(x: u(at: v), y: v)
        }
    }

    var outerLeft: Line
    var innerLeft: Line
    var innerRight: Line
    var outerRight: Line

    init(outerLeft: Line, innerLeft: Line, innerRight: Line, outerRight: Line) {
        self.outerLeft = outerLeft
        self.innerLeft = innerLeft
        self.innerRight = innerRight
        self.outerRight = outerRight
    }

    init(geometry: VShapeGeometry) {
        outerLeft = Line(through: CGPoint(x: geometry.outerLeftTop, y: 0), geometry.vertex)
        innerLeft = Line(through: CGPoint(x: geometry.innerLeftTop, y: 0), geometry.notchApex)
        innerRight = Line(through: CGPoint(x: geometry.innerRightTop, y: 0), geometry.notchApex)
        outerRight = Line(through: CGPoint(x: geometry.outerRightTop, y: 0), geometry.vertex)
    }

    /// The bottom point, where the outer edges meet.
    var vertex: CGPoint? { outerLeft.intersection(with: outerRight) }

    /// The bottom of the notch, where the inner edges meet.
    var notchApex: CGPoint? { innerLeft.intersection(with: innerRight) }

    /// The point halfway between the notch apex and the vertex, which the V scales around.
    var middle: CGPoint? {
        guard let vertex, let notchApex else { return nil }
        return CGPoint(x: (vertex.x + notchApex.x) / 2, y: (vertex.y + notchApex.y) / 2)
    }

    /// The outline scaled around its middle.
    func scaled(by factor: Double) -> VShapeOutline {
        guard let middle, factor != 1 else { return self }
        return VShapeOutline(
            outerLeft: outerLeft.scaled(by: factor, around: middle),
            innerLeft: innerLeft.scaled(by: factor, around: middle),
            innerRight: innerRight.scaled(by: factor, around: middle),
            outerRight: outerRight.scaled(by: factor, around: middle)
        )
    }

    /// The outline with every edge moved outward by a distance, so the filled area grows. A negative
    /// distance moves every edge inward. The outer edges move away from the V's centre, and the
    /// notch's edges move into the notch.
    func expanded(by distance: Double) -> VShapeOutline {
        VShapeOutline(
            outerLeft: outerLeft.offset(by: -distance),
            innerLeft: innerLeft.offset(by: distance),
            innerRight: innerRight.offset(by: -distance),
            outerRight: outerRight.offset(by: distance)
        )
    }

    /// The filled polygon in design units, with the strokes cut off at height `top`.
    ///
    /// Returns the six corners of the V with its notch, or the three corners of a triangle if the
    /// notch is entirely above `top`, or nothing if the whole V is above `top` or the outline is
    /// inconsistent.
    func polygon(top: Double) -> [CGPoint] {
        guard let vertex, Double(vertex.y) > top else { return [] }
        let outerLeftTop = CGPoint(x: outerLeft.u(at: top), y: top)
        let outerRightTop = CGPoint(x: outerRight.u(at: top), y: top)
        guard outerLeftTop.x < outerRightTop.x else { return [] }

        guard let notchApex, Double(notchApex.y) > top else {
            return [outerLeftTop, vertex, outerRightTop]
        }
        let innerLeftTop = CGPoint(x: innerLeft.u(at: top), y: top)
        let innerRightTop = CGPoint(x: innerRight.u(at: top), y: top)
        let apexV = Double(notchApex.y)
        let notchFitsInside = outerLeftTop.x < innerLeftTop.x
            && innerLeftTop.x < innerRightTop.x
            && innerRightTop.x < outerRightTop.x
            && apexV < Double(vertex.y)
            && outerLeft.u(at: apexV) < Double(notchApex.x)
            && Double(notchApex.x) < outerRight.u(at: apexV)
        guard notchFitsInside else { return [] }
        return [outerLeftTop, vertex, outerRightTop, innerRightTop, notchApex, innerLeftTop]
    }

    /// The filled polygon, converted from design units to points, with the strokes cut off at the
    /// composition's top edge.
    ///
    /// - Parameters:
    ///   - unit: Points per design unit, which is the composition's width.
    ///   - origin: The composition's top-left corner.
    func path(unit: CGFloat, origin: CGPoint) -> Path {
        let corners = polygon(top: 0)
        guard corners.count >= 3 else { return Path() }
        var path = Path()
        path.addLines(corners.map { CGPoint(x: origin.x + $0.x * unit, y: origin.y + $0.y * unit) })
        path.closeSubpath()
        return path
    }
}
