import AnimationBGView
import SwiftUI

/// Palettes to try. Only `reference` comes from the reference images; the others show that any
/// colours work without changing the motion.
enum PalettePreset: String, CaseIterable, Identifiable {
    case reference, mint, lavender, blush

    var id: Self { self }

    var name: String {
        switch self {
        case .reference: "Reference"
        case .mint: "Mint"
        case .lavender: "Lavender"
        case .blush: "Blush"
        }
    }

    var palette: BackgroundColorPalette {
        switch self {
        case .reference:
            .reference
        case .mint:
            BackgroundColorPalette(
                base: Color(hex: 0xE8F6EF),
                lights: [Color(hex: 0x8FD9BF), Color(hex: 0x9FCCE8), Color(hex: 0xCDE89E), Color(hex: 0x8DB8B3)]
            )
        case .lavender:
            BackgroundColorPalette(
                base: Color(hex: 0xF1EAF6),
                lights: [Color(hex: 0xC7B6E8), Color(hex: 0xF2B8C6), Color(hex: 0xF6CFA3), Color(hex: 0xA9A3D6)]
            )
        case .blush:
            BackgroundColorPalette(
                base: Color(hex: 0xFBEDEA),
                lights: [Color(hex: 0xF5B7A8), Color(hex: 0xF9D58A), Color(hex: 0xE8A0B4), Color(hex: 0xD9B8A3)]
            )
        }
    }
}

extension Color {
    /// An opaque sRGB colour from a `0xRRGGBB` value.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
