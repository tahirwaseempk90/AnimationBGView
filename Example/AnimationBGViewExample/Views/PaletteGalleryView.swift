import AnimationBGView
import SwiftUI

/// The same motion in different colours. Choosing a palette applies it everywhere in the app.
struct PaletteGalleryView: View {
    @Binding var configuration: AnimatedBackgroundConfiguration
    @Binding var palette: PalettePreset

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("A palette only holds colours, so changing it keeps the motion exactly as it is.")
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(PalettePreset.allCases) { preset in
                        swatch(for: preset)
                    }
                }
                code
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Palettes")
    }

    private func swatch(for preset: PalettePreset) -> some View {
        Button {
            palette = preset
            configuration.palette = preset.palette
        } label: {
            VStack(spacing: 8) {
                AnimatedBackgroundView(configuration: previewConfiguration(for: preset))
                    .aspectRatio(390 / 640, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                preset == palette ? Color.primary : Color.primary.opacity(0.1),
                                lineWidth: preset == palette ? 2 : 1
                            )
                    }
                HStack(spacing: 6) {
                    if preset == palette { Image(systemName: "checkmark.circle.fill") }
                    Text(preset.name).font(.subheadline.weight(.semibold))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("palette-\(preset.rawValue)")
        .accessibilityLabel(preset.name)
        .accessibilityAddTraits(preset == palette ? .isSelected : [])
    }

    private func previewConfiguration(for preset: PalettePreset) -> AnimatedBackgroundConfiguration {
        var preview = configuration
        preview.palette = preset.palette
        preview.ignoresSafeArea = false
        return preview
    }

    private var code: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your own colours").font(.headline)
            Text("""
            configuration.palette = BackgroundColorPalette(
                base: Color(red: 0.91, green: 0.96, blue: 0.94),
                lights: [.mint, .teal, .cyan, .green]
            )
            """)
            .font(.system(.footnote, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
