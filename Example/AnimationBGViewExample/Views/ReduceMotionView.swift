import AnimationBGView
import SwiftUI

/// What people with Reduce Motion see, next to what everyone else sees.
struct ReduceMotionView: View {
    let configuration: AnimatedBackgroundConfiguration
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                status
                HStack(alignment: .top, spacing: 16) {
                    preview("Animated", policy: .never)
                    preview("With Reduce Motion", policy: .always)
                }
                notes
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Motion")
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(reduceMotion ? "Reduce Motion is on" : "Reduce Motion is off", systemImage: reduceMotion ? "pause.circle" : "play.circle")
                .font(.headline)
                .accessibilityIdentifier("reduce-motion-status")
            Text("Settings › Accessibility › Motion › Reduce Motion. When it's on, the background shows a still image instead of moving.")
                .foregroundStyle(.secondary)
        }
    }

    private func preview(_ title: String, policy: ReduceMotionPolicy) -> some View {
        var preview = configuration
        preview.motion.reduceMotion = policy
        preview.ignoresSafeArea = false
        return VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            AnimatedBackgroundView(configuration: preview)
                .aspectRatio(390 / 700, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.primary.opacity(0.1))
                }
        }
        .frame(maxWidth: .infinity)
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 12) {
            note("The still image is `motion.staticPhase`, the arrangement of the colour reference by default.", symbol: "photo")
            note(
                "`motion.reduceMotion` can follow the system, always reduce, or never reduce, for apps with their own motion setting.",
                symbol: "switch.2"
            )
            note("The background is decorative, so it's hidden from VoiceOver. Only your content is read.", symbol: "speaker.slash")
            note("It stops drawing whenever the app isn't active, and continues from the same frame.", symbol: "moon.zzz")
        }
    }

    private func note(_ text: LocalizedStringKey, symbol: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol).foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}
