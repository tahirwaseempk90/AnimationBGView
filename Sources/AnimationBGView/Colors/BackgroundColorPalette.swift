import SwiftUI

/// The colours of the background: a base colour, one colour per moving light, and the colour of the V.
///
/// The palette only holds colours. Where the lights are and how they move is described separately,
/// by ``GradientConfiguration``, so you can recolour the background without changing its motion:
///
/// ```swift
/// var configuration = AnimatedBackgroundConfiguration()
/// configuration.palette = BackgroundColorPalette(
///     base: Color(red: 0.93, green: 0.97, blue: 0.95),
///     lights: [.mint, .teal, .cyan, .green]
/// )
/// ```
///
/// Light `n` takes colour `n` from ``lights``. If there are more lights than colours, the colours
/// repeat from the start. With no colours, the lights aren't drawn.
public struct BackgroundColorPalette: Equatable, Sendable {
    /// The colour that fills the whole background.
    public var base: Color

    /// The colours of the moving lights, in the same order as ``GradientConfiguration/lights``.
    public var lights: [Color]

    /// The colour of the V. It's drawn at ``VShapeConfiguration/opacity`` over the lights.
    ///
    /// In the reference, the V is the base colour, so it reads as a window of calm in the moving colour.
    public var vShape: Color

    /// Creates a palette.
    ///
    /// - Parameters:
    ///   - base: The colour that fills the background.
    ///   - lights: The colours of the moving lights, in order.
    ///   - vShape: The colour of the V. `nil` uses `base`, as in the reference.
    public init(base: Color, lights: [Color], vShape: Color? = nil) {
        self.base = base
        self.lights = lights
        self.vShape = vShape ?? base
    }

    /// The colour for the light at an index, repeating the colours if needed, or `nil` if there are none.
    public func lightColor(at index: Int) -> Color? {
        guard !lights.isEmpty, index >= 0 else { return nil }
        return lights[index % lights.count]
    }
}

extension BackgroundColorPalette {
    /// The palette measured from the reference images.
    ///
    /// | Colour | Value | Source |
    /// |---|---|---|
    /// | Base | `#FAEEA3` | The dominant colour of the shape reference |
    /// | Green-yellow light | `#DEEB94` | The strongest green in the reference recording |
    /// | Golden light | `#F5DD6D` | The most saturated colour of the colour reference |
    /// | Peach light | `#F3C485` | The reddest colour of the colour reference |
    /// | Tan light | `#DDC48F` | The darkest colour of the colour reference |
    /// | V | The base colour | The recording |
    public static let reference = BackgroundColorPalette(
        base: Color(hex: ReferenceColors.base),
        lights: ReferenceColors.lights.map(Color.init(hex:))
    )
}

/// The reference colours as `0xRRGGBB` values, kept here so tests can check them exactly.
enum ReferenceColors {
    static let base: UInt32 = 0xFAEEA3
    static let greenYellow: UInt32 = 0xDEEB94
    static let golden: UInt32 = 0xF5DD6D
    static let peach: UInt32 = 0xF3C485
    static let tan: UInt32 = 0xDDC48F
    static let lights: [UInt32] = [greenYellow, golden, peach, tan]
}
