import CoreGraphics
import XCTest
@testable import AnimationBGView

final class CompositionLayoutTests: XCTestCase {
    func testPortraitPhonesUseTheFullWidth() {
        for size in [CGSize(width: 390, height: 844), CGSize(width: 375, height: 667), CGSize(width: 440, height: 956)] {
            let layout = CompositionLayout(size: size, scaling: .fit)
            XCTAssertEqual(layout.unit, size.width)
            XCTAssertEqual(layout.origin, .zero)
        }
    }

    func testPortraitIPadsUseTheFullWidth() {
        let layout = CompositionLayout(size: CGSize(width: 820, height: 1_180), scaling: .fit)
        XCTAssertEqual(layout.unit, 820)
        XCTAssertEqual(layout.origin, .zero)
    }

    func testShortWideViewsShrinkTheCompositionToFit() {
        let layout = CompositionLayout(size: CGSize(width: 844, height: 390), scaling: .fit)
        XCTAssertEqual(layout.unit, 325, accuracy: 1e-9)
        XCTAssertEqual(layout.origin.x, (844 - 325) / 2, accuracy: 1e-9)
        XCTAssertEqual(layout.origin.y, 0)
        XCTAssertEqual(layout.compositionRect.height, 390, accuracy: 1e-9, "The composition exactly fills the height")
        XCTAssertEqual(layout.compositionRect.midX, 422, accuracy: 1e-9, "and is centred")
    }

    func testSquareViews() {
        let layout = CompositionLayout(size: CGSize(width: 300, height: 300), scaling: .fit)
        XCTAssertEqual(layout.unit, 250, accuracy: 1e-9)
        XCTAssertEqual(layout.origin.x, 25, accuracy: 1e-9)
    }

    func testFillWidthAlwaysUsesTheWidth() {
        let layout = CompositionLayout(size: CGSize(width: 844, height: 390), scaling: .fillWidth)
        XCTAssertEqual(layout.unit, 844)
        XCTAssertEqual(layout.origin, .zero)
    }

    func testConversion() {
        let layout = CompositionLayout(size: CGSize(width: 844, height: 390), scaling: .fit)
        let point = layout.point(CGPoint(x: 0.5, y: 0.5))
        XCTAssertEqual(point.x, 259.5 + 162.5, accuracy: 1e-9)
        XCTAssertEqual(point.y, 162.5, accuracy: 1e-9)
        XCTAssertEqual(layout.length(0.1), 32.5, accuracy: 1e-9)
    }

    func testDegenerateSizesProduceAnEmptyComposition() {
        let sizes = [CGSize.zero, CGSize(width: -100, height: 50), CGSize(width: CGFloat.nan, height: 100),
                     CGSize(width: 100, height: CGFloat.infinity), CGSize(width: 100, height: 0)]
        for size in sizes {
            for scaling in [CompositionScaling.fit, .fillWidth] {
                let layout = CompositionLayout(size: size, scaling: scaling)
                XCTAssertTrue(layout.unit.isFinite, "\(size)")
                XCTAssertTrue(layout.origin.x.isFinite, "\(size)")
                XCTAssertGreaterThanOrEqual(layout.unit, 0, "\(size)")
            }
        }
        XCTAssertEqual(CompositionLayout(size: CGSize(width: 100, height: 0), scaling: .fit).unit, 0)
    }
}
