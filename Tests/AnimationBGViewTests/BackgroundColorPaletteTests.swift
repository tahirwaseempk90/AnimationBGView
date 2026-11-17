import SwiftUI
import XCTest
@testable import AnimationBGView

final class BackgroundColorPaletteTests: XCTestCase {
    func testReferenceValuesAreTheMeasuredColours() {
        XCTAssertEqual(ReferenceColors.base, 0xFAEEA3)
        XCTAssertEqual(ReferenceColors.lights, [0xDEEB94, 0xF5DD6D, 0xF3C485, 0xDDC48F])
    }

    func testReferencePaletteResolvesToTheMeasuredColours() throws {
        guard #available(iOS 17.0, macOS 14.0, *) else { throw XCTSkip("Color.resolve(in:) needs iOS 17 or macOS 14.") }
        let palette = BackgroundColorPalette.reference
        assertColor(palette.base, equals: ReferenceColors.base)
        XCTAssertEqual(palette.lights.count, ReferenceColors.lights.count)
        for (color, hex) in zip(palette.lights, ReferenceColors.lights) {
            assertColor(color, equals: hex)
        }
        assertColor(palette.vShape, equals: ReferenceColors.base)
    }

    func testEachReferenceColourHasTheRoleItWasMeasuredFor() {
        // The order matters: light n takes colour n, and the lights' paths were fitted per colour.
        let lights = ReferenceColors.lights.map(RGB.init(hex:))
        let greenYellow = lights[0], golden = lights[1], peach = lights[2], tan = lights[3]
        XCTAssertEqual(lights.max { $0.green - $0.red < $1.green - $1.red }, greenYellow, "Green-yellow is the greenest")
        XCTAssertEqual(lights.min { $0.blue < $1.blue }, golden, "Golden is the most saturated yellow")
        XCTAssertEqual(lights.max { $0.red - $0.green < $1.red - $1.green }, peach, "Peach is the reddest")
        XCTAssertEqual(lights.min { $0.luminance < $1.luminance }, tan, "Tan is the darkest")
        // Every light is darker than the base, so the lights read as colour on a pale ground.
        let base = RGB(hex: ReferenceColors.base)
        XCTAssertTrue(lights.allSatisfy { $0.luminance < base.luminance })
    }

    func testThereIsOneColourForEachReferenceLight() {
        XCTAssertEqual(BackgroundColorPalette.reference.lights.count, GradientLight.reference.count)
    }

    func testTheVDefaultsToTheBaseColour() {
        let palette = BackgroundColorPalette(base: .mint, lights: [.red])
        XCTAssertEqual(palette.vShape, .mint)
        XCTAssertEqual(BackgroundColorPalette(base: .mint, lights: [], vShape: .white).vShape, .white)
    }

    func testLightColoursRepeatWhenThereAreFewerColoursThanLights() {
        let palette = BackgroundColorPalette(base: .white, lights: [.red, .blue])
        XCTAssertEqual(palette.lightColor(at: 0), .red)
        XCTAssertEqual(palette.lightColor(at: 1), .blue)
        XCTAssertEqual(palette.lightColor(at: 2), .red)
        XCTAssertEqual(palette.lightColor(at: 5), .blue)
        XCTAssertNil(palette.lightColor(at: -1))
        XCTAssertNil(BackgroundColorPalette(base: .white, lights: []).lightColor(at: 0))
    }

    func testCustomPalettesAreValues() {
        let custom = BackgroundColorPalette(base: .white, lights: [.red, .green])
        var copy = custom
        XCTAssertEqual(copy, custom)
        copy.lights.append(.blue)
        XCTAssertNotEqual(copy, custom)
        XCTAssertNotEqual(custom, .reference)
    }

    @available(iOS 17.0, macOS 14.0, *)
    private func assertColor(_ color: Color, equals hex: UInt32, file: StaticString = #filePath, line: UInt = #line) {
        let resolved = color.resolve(in: EnvironmentValues())
        let expected = RGB(hex: hex)
        XCTAssertEqual(Double(resolved.red) * 255, Double(expected.red), accuracy: 0.6, "red", file: file, line: line)
        XCTAssertEqual(Double(resolved.green) * 255, Double(expected.green), accuracy: 0.6, "green", file: file, line: line)
        XCTAssertEqual(Double(resolved.blue) * 255, Double(expected.blue), accuracy: 0.6, "blue", file: file, line: line)
        XCTAssertEqual(Double(resolved.opacity), 1, accuracy: 0.001, file: file, line: line)
    }
}

private struct RGB: Equatable {
    let red: Int
    let green: Int
    let blue: Int

    init(hex: UInt32) {
        red = Int((hex >> 16) & 0xFF)
        green = Int((hex >> 8) & 0xFF)
        blue = Int(hex & 0xFF)
    }

    var luminance: Double { 0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue) }
}
