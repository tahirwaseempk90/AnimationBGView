import SwiftUI

extension Color {
    /// Creates an opaque sRGB colour from a `0xRRGGBB` value.
    ///
    /// Internal on purpose: many apps define their own `Color(hex:)`, and a public one here would make
    /// their calls ambiguous.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
