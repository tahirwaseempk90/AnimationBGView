import AnimationBGView
import SwiftUI

/// The background full screen, with some content over it.
struct HomeView: View {
    let configuration: AnimatedBackgroundConfiguration
    let showsContent: Bool
    let customize: () -> Void
    let open: (LaunchOptions.Screen) -> Void

    var body: some View {
        ZStack {
            AnimatedBackgroundView(configuration: configuration)
                // The UI tests check that this identifier never appears: the background is hidden
                // from VoiceOver and other assistive technologies.
                .accessibilityIdentifier("animated-background")
            if showsContent {
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("AnimationBGView")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("home-title")
                Text("Soft light drifting behind a large V, drawn entirely with SwiftUI.")
                    .font(.title3)
                    .foregroundStyle(.black.opacity(0.62))
            }
            .padding(.top, 28)

            Spacer(minLength: 24)

            facts
                .padding(.bottom, 16)
            actions
        }
        .foregroundStyle(.black.opacity(0.85))
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .frame(maxWidth: 600)
    }

    private var facts: some View {
        HStack(spacing: 0) {
            fact(value: configuration.motion.isEnabled ? cycle : "Still", label: "per cycle")
            Divider().frame(height: 32)
            fact(value: "\(configuration.gradient.lights.count)", label: "lights")
            Divider().frame(height: 32)
            fact(value: "\(Int(configuration.motion.frameRate)) fps", label: "at most")
        }
        .padding(.vertical, 12)
        .background(.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var cycle: String {
        let speed = max(configuration.motion.speed, 0.01)
        return (configuration.motion.cycleDuration / speed).formatted(.number.precision(.fractionLength(0...1))) + " s"
    }

    private func fact(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.black.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button(action: customize) {
                Label("Customize", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("customize-button")

            HStack(spacing: 10) {
                secondaryButton("Palettes", systemImage: "paintpalette", screen: .palettes)
                secondaryButton("Layouts", systemImage: "rectangle.3.group", screen: .layouts)
                secondaryButton("Motion", systemImage: "figure.walk.motion", screen: .accessibility)
            }
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, systemImage: String, screen: LaunchOptions.Screen) -> some View {
        Button {
            open(screen)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.body.weight(.semibold))
                Text(title).font(.footnote.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityIdentifier("\(screen.rawValue)-button")
    }
}

#Preview {
    HomeView(configuration: .default, showsContent: true, customize: {}, open: { _ in })
}
