import AnimationBGView
import SwiftUI

/// The background in frames of different shapes, to show how it adapts.
struct LayoutGalleryView: View {
    let configuration: AnimatedBackgroundConfiguration

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("""
                The background fills whatever frame it's given. Its composition is sized from the width, \
                so the V keeps its proportions, and shrinks when a frame is short and wide.
                """)
                .foregroundStyle(.secondary)

                sample(
                    "Phone, portrait",
                    detail: "As wide as the frame, with the V reaching halfway down.",
                    aspectRatio: 390 / 844,
                    maxHeight: 440
                )
                sample(
                    "Phone, landscape · Fit",
                    detail: "The default: the composition shrinks to fit the height and is centred.",
                    aspectRatio: 844 / 390
                )
                sample(
                    "Phone, landscape · Fill width",
                    detail: "Always as wide as the frame. The bottom of the V runs past the bottom edge.",
                    aspectRatio: 844 / 390,
                    scaling: .fillWidth
                )
                sample(
                    "Tablet, portrait",
                    detail: "As wide as the frame. The V reaches three quarters of the way down.",
                    aspectRatio: 820 / 1_180,
                    maxHeight: 440
                )
                HStack(alignment: .top, spacing: 16) {
                    sample("Square card", detail: "Inside a card, with safe areas respected.", aspectRatio: 1)
                    sample("Tall card", detail: "Narrow frames work the same way.", aspectRatio: 0.6)
                }
                sample("Banner", detail: "A short strip shows a small, centred V.", aspectRatio: 3)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Layouts")
    }

    private func sample(
        _ title: String,
        detail: String,
        aspectRatio: CGFloat,
        maxHeight: CGFloat = .infinity,
        scaling: CompositionScaling = .fit
    ) -> some View {
        var sampleConfiguration = configuration
        sampleConfiguration.scaling = scaling
        sampleConfiguration.ignoresSafeArea = false
        return VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
            // Clip and outline the background itself, then centre it, so the outline hugs the frame
            // being demonstrated rather than the whole row.
            AnimatedBackgroundView(configuration: sampleConfiguration)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.primary.opacity(0.1))
                }
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
        }
        .accessibilityElement(children: .combine)
    }
}
