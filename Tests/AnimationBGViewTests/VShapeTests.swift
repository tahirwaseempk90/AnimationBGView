import SwiftUI
import XCTest
@testable import AnimationBGView

final class VShapeTests: XCTestCase {
    private let reference = VShapeOutline(geometry: .reference)
    private let phone = CGRect(x: 0, y: 0, width: 390, height: 844)

    // MARK: - Measured geometry

    func testReferenceGeometryIsValid() {
        XCTAssertTrue(VShapeGeometry.reference.isValid)
    }

    func testOutlineReproducesTheMeasuredCorners() throws {
        let vertex = try XCTUnwrap(reference.vertex)
        let notchApex = try XCTUnwrap(reference.notchApex)
        XCTAssertEqual(vertex.x, 0.6372, accuracy: 1e-9)
        XCTAssertEqual(vertex.y, 1.0676, accuracy: 1e-9)
        XCTAssertEqual(notchApex.x, 0.6882, accuracy: 1e-9)
        XCTAssertEqual(notchApex.y, 0.5740, accuracy: 1e-9)
    }

    func testEdgesLeanAtTheMeasuredAngles() {
        // Measured from Shape.png, and confirmed by the recording to within 0.5°.
        let angles = [reference.outerLeft, reference.innerLeft, reference.innerRight, reference.outerRight]
            .map { atan($0.slope) * 180 / .pi }
        for (angle, measured) in zip(angles, [20.0, 19.1, -16.5, -18.7]) {
            XCTAssertEqual(angle, measured, accuracy: 0.1)
        }
    }

    func testLeftStrokeIsThickAndRightStrokeIsThin() {
        let topLeft = reference.innerLeft.u(at: 0) - reference.outerLeft.u(at: 0)
        let topRight = reference.outerRight.u(at: 0) - reference.innerRight.u(at: 0)
        XCTAssertEqual(topLeft, 0.2399, accuracy: 1e-4)
        XCTAssertEqual(topRight, 0.1394, accuracy: 1e-4)
        // Like the letter V in many typefaces, and as measured, the thin stroke tapers toward the bottom.
        let apex = 0.574
        let apexLeft = reference.innerLeft.u(at: apex) - reference.outerLeft.u(at: apex)
        let apexRight = reference.outerRight.u(at: apex) - reference.innerRight.u(at: apex)
        XCTAssertGreaterThan(topLeft / topRight, 1.6)
        XCTAssertLessThan(apexRight, topRight)
        XCTAssertEqual(apexLeft, topLeft, accuracy: 0.015, "The thick stroke stays almost parallel")
    }

    func testTheVSitsRightOfCentre() throws {
        let vertex = try XCTUnwrap(reference.vertex)
        let notchApex = try XCTUnwrap(reference.notchApex)
        XCTAssertGreaterThan(vertex.x, 0.6)
        XCTAssertGreaterThan(notchApex.x, vertex.x, "The thick left stroke pushes the notch to the right")
    }

    // MARK: - Path

    // `Path` stores its points as 32-bit floats, so point comparisons allow for that precision.

    func testPathBoundsInAPhoneSizedRect() {
        let bounds = VShape().path(in: phone).boundingRect
        XCTAssertEqual(bounds.minX, 0.2497 * 390, accuracy: 1e-3)
        XCTAssertEqual(bounds.maxX, 0.9981 * 390, accuracy: 1e-3)
        XCTAssertEqual(bounds.minY, 0, accuracy: 1e-3)
        XCTAssertEqual(bounds.maxY, 1.0676 * 390, accuracy: 1e-3)
    }

    func testPathKeepsItsProportionsInAnyRect() {
        // The width alone sets the scale, so the V is never stretched.
        let short = VShape().path(in: CGRect(x: 0, y: 0, width: 390, height: 200)).boundingRect
        let tall = VShape().path(in: CGRect(x: 0, y: 0, width: 390, height: 2_000)).boundingRect
        XCTAssertEqual(short, tall)

        let wide = VShape().path(in: CGRect(x: 0, y: 0, width: 1_024, height: 300)).boundingRect
        let narrow = VShape().path(in: phone).boundingRect
        XCTAssertEqual(wide.width / wide.height, narrow.width / narrow.height, accuracy: 1e-6)
        XCTAssertEqual(wide.width / narrow.width, 1_024 / 390, accuracy: 1e-6)
    }

    func testPathFollowsTheRectsOrigin() {
        let moved = VShape().path(in: CGRect(x: 40, y: 25, width: 390, height: 844)).boundingRect
        let origin = VShape().path(in: phone).boundingRect
        XCTAssertEqual(moved.minX - origin.minX, 40, accuracy: 1e-3)
        XCTAssertEqual(moved.minY - origin.minY, 25, accuracy: 1e-3)
    }

    func testWhichPointsAreInsideTheV() {
        let path = VShape().path(in: phone)
        func inside(_ u: Double, _ v: Double) -> Bool { path.contains(CGPoint(x: u * 390, y: v * 390)) }
        XCTAssertTrue(inside(0.476, 0.3), "Middle of the left stroke")
        XCTAssertTrue(inside(0.833, 0.3), "Middle of the right stroke")
        XCTAssertTrue(inside(0.634, 0.8), "Below the notch, where the strokes join")
        XCTAssertFalse(inside(0.68, 0.3), "In the notch")
        XCTAssertFalse(inside(0.1, 0.3), "Left of the V")
        XCTAssertFalse(inside(0.95, 0.3), "Right of the V")
        XCTAssertFalse(inside(0.637, 1.1), "Below the vertex")
    }

    func testStrokesAlwaysReachTheTopEdge() {
        for scale in [0.25, 0.5, 1, 2, 3] {
            let bounds = VShape(scale: scale).path(in: phone).boundingRect
            XCTAssertEqual(bounds.minY, 0, accuracy: 1e-9, "scale \(scale)")
        }
    }

    func testEmptyAndInvalidRectsDrawNothing() {
        XCTAssertTrue(VShape().path(in: .zero).isEmpty)
        XCTAssertTrue(VShape().path(in: CGRect(x: 0, y: 0, width: 0, height: 100)).isEmpty)
        XCTAssertTrue(VShape().path(in: CGRect(x: CGFloat.nan, y: 0, width: 100, height: 100)).isEmpty)
        XCTAssertTrue(VShape().path(in: .infinite).isEmpty)
    }

    func testNegativeSizesAreTreatedLikeTheirStandardizedRect() {
        // As everywhere in Core Graphics, a rectangle with a negative width spans the same area as
        // its standardized form.
        let flipped = CGRect(x: 390, y: 0, width: -390, height: 844)
        XCTAssertEqual(VShape().path(in: flipped).boundingRect, VShape().path(in: phone).boundingRect)
    }

    // MARK: - Invalid geometry

    func testInvalidGeometryIsRejectedAndDrawsNothing() {
        var outOfOrder = VShapeGeometry.reference
        outOfOrder.innerLeftTop = 0.9

        var notchBelowVertex = VShapeGeometry.reference
        notchBelowVertex.notchApex = CGPoint(x: 0.64, y: 1.2)

        var notchOutside = VShapeGeometry.reference
        notchOutside.notchApex = CGPoint(x: 0.95, y: 0.574)

        var aboveTheTop = VShapeGeometry.reference
        aboveTheTop.vertex = CGPoint(x: 0.6, y: -0.1)

        var notANumber = VShapeGeometry.reference
        notANumber.outerRightTop = .nan

        for geometry in [outOfOrder, notchBelowVertex, notchOutside, aboveTheTop, notANumber] {
            XCTAssertFalse(geometry.isValid)
            XCTAssertTrue(VShape(geometry: geometry).path(in: phone).isEmpty)
        }
    }

    // MARK: - Scale

    func testScalingKeepsTheMiddleFixed() throws {
        let doubled = reference.scaled(by: 2)
        let middle = try XCTUnwrap(reference.middle)
        let doubledMiddle = try XCTUnwrap(doubled.middle)
        XCTAssertEqual(doubledMiddle.x, middle.x, accuracy: 1e-9)
        XCTAssertEqual(doubledMiddle.y, middle.y, accuracy: 1e-9)

        let vertex = try XCTUnwrap(reference.vertex)
        let doubledVertex = try XCTUnwrap(doubled.vertex)
        XCTAssertEqual(doubledVertex.x - middle.x, 2 * (vertex.x - middle.x), accuracy: 1e-9)
        XCTAssertEqual(doubledVertex.y - middle.y, 2 * (vertex.y - middle.y), accuracy: 1e-9)
        XCTAssertEqual(doubled.outerLeft.slope, reference.outerLeft.slope, "Scaling doesn't change the angles")
    }

    func testScaleIsAnimatable() {
        var shape = VShape(scale: 1.3)
        XCTAssertEqual(shape.animatableData, 1.3)
        shape.animatableData = 0.7
        XCTAssertEqual(shape.scale, 0.7)
    }

    func testOutOfRangeScaleIsClamped() {
        XCTAssertEqual(VShape(scale: 50).path(in: phone).boundingRect, VShape(scale: 3).path(in: phone).boundingRect)
        XCTAssertEqual(VShape(scale: .nan).path(in: phone).boundingRect, VShape().path(in: phone).boundingRect)
    }

    // MARK: - Polygon

    func testPolygonHasSixCornersWithItsNotch() {
        XCTAssertEqual(reference.polygon(top: 0).count, 6)
    }

    func testPolygonLosesItsNotchWhenTheNotchIsAboveTheCut() {
        XCTAssertEqual(reference.polygon(top: 0.6).count, 3, "Cut below the notch apex")
        XCTAssertTrue(reference.polygon(top: 1.1).isEmpty, "Cut below the vertex")
    }

    // MARK: - Soft edges

    func testExpandingMovesEveryEdgeByTheSameDistance() {
        let distance = 0.01
        let expanded = reference.expanded(by: distance)
        let pairs = [(reference.outerLeft, expanded.outerLeft), (reference.innerLeft, expanded.innerLeft),
                     (reference.innerRight, expanded.innerRight), (reference.outerRight, expanded.outerRight)]
        for (original, moved) in pairs {
            XCTAssertEqual(abs(moved.intercept - original.intercept) / (1 + original.slope * original.slope).squareRoot(), distance, accuracy: 1e-12)
            XCTAssertEqual(moved.slope, original.slope)
        }
    }

    func testExpandingGrowsTheVAndShrinksTheNotch() throws {
        let grown = reference.expanded(by: 0.01)
        let shrunk = reference.expanded(by: -0.01)
        XCTAssertGreaterThan(try XCTUnwrap(grown.vertex).y, try XCTUnwrap(reference.vertex).y)
        XCTAssertLessThan(try XCTUnwrap(grown.notchApex).y, try XCTUnwrap(reference.notchApex).y)
        XCTAssertLessThan(try XCTUnwrap(shrunk.vertex).y, try XCTUnwrap(reference.vertex).y)

        let width = { (outline: VShapeOutline) in outline.innerLeft.u(at: 0.3) - outline.outerLeft.u(at: 0.3) }
        XCTAssertGreaterThan(width(grown), width(reference))
        XCTAssertLessThan(width(shrunk), width(reference))
    }

    func testFeatherLayersAddUpToTheConfiguredOpacity() throws {
        let vShape = VShapeConfiguration.default
        let layers = VShapeRenderer.layers(for: vShape)
        XCTAssertEqual(layers.count, VShapeRenderer.featherLayerCount)
        let combined = 1 - layers.reduce(1) { $0 * (1 - $1.opacity) }
        XCTAssertEqual(combined, vShape.opacity, accuracy: 1e-12)
        // Spread evenly from half the softness inside each edge to half outside it.
        let expansions = layers.map(\.expansion)
        XCTAssertEqual(try XCTUnwrap(expansions.first), -vShape.edgeSoftness / 2, accuracy: 1e-12)
        XCTAssertEqual(try XCTUnwrap(expansions.last), vShape.edgeSoftness / 2, accuracy: 1e-12)
        XCTAssertEqual(expansions, expansions.sorted())
        XCTAssertEqual(expansions.reduce(0, +), 0, accuracy: 1e-12)
    }

    func testFeatherRampsInEqualStepsAtAnyOpacity() {
        // A point covered by the r largest copies should have r/n of the full opacity: a straight
        // ramp across the edge. This has to hold for an opaque V too, where equal-opacity copies
        // would collapse into one hard edge.
        for opacity in [0.2, 0.58, 0.9, 1] {
            let layers = VShapeRenderer.layers(for: VShapeConfiguration(opacity: opacity))
            let largestFirst = layers.sorted { $0.expansion > $1.expansion }
            var transparency = 1.0
            for (index, layer) in largestFirst.enumerated() {
                transparency *= 1 - layer.opacity
                let expected = opacity * Double(index + 1) / Double(layers.count)
                XCTAssertEqual(1 - transparency, expected, accuracy: 1e-12, "opacity \(opacity), step \(index + 1)")
            }
        }
    }

    func testCrispEdgesUseOneLayerAndInvisibleVsUseNone() {
        XCTAssertEqual(VShapeRenderer.layers(for: VShapeConfiguration(edgeSoftness: 0)), [.init(expansion: 0, opacity: 0.58)])
        XCTAssertTrue(VShapeRenderer.layers(for: VShapeConfiguration(opacity: 0)).isEmpty)
        let opaque = VShapeRenderer.layers(for: VShapeConfiguration(opacity: 1))
        XCTAssertEqual(opaque.filter { $0.opacity == 1 }.count, 1, "Only the innermost copy is opaque")
    }
}
