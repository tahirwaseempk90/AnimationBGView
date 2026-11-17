import AnimationBGView
import SwiftUI

/// Every setting, applied as you change it. At half height the panel leaves the top of the screen,
/// where the V and the lights are, in view.
struct CustomizationPanel: View {
    @Binding var configuration: AnimatedBackgroundConfiguration
    @Binding var palette: PalettePreset
    let defaults: (configuration: AnimatedBackgroundConfiguration, palette: PalettePreset)

    var body: some View {
        NavigationStack {
            Form {
                animationSection
                stillImageSection
                colourSection
                vShapeSection
                layoutSection
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        configuration = defaults.configuration
                        palette = defaults.palette
                    }
                    .disabled(configuration == defaults.configuration)
                    .accessibilityIdentifier("reset-button")
                }
            }
            .onChange(of: palette) { _, newValue in
                configuration.palette = newValue.palette
            }
        }
    }

    // MARK: - Sections

    private var animationSection: some View {
        Section {
            Toggle("Animate", isOn: $configuration.motion.isEnabled)
                .accessibilityIdentifier("animate-toggle")
            SliderRow(title: "Speed", value: $configuration.motion.speed, range: 0...8, step: 0.25) {
                $0.formatted(.number.precision(.fractionLength(2))) + "×"
            }
            SliderRow(title: "Motion", value: $configuration.motion.intensity, range: 0...2, step: 0.05) {
                $0.formatted(.percent.precision(.fractionLength(0)))
            }
            Picker("Frame rate", selection: $configuration.motion.frameRate) {
                ForEach([15.0, 30, 60, 120], id: \.self) { Text("\(Int($0)) fps").tag($0) }
            }
            Picker("Reduce Motion", selection: $configuration.motion.reduceMotion) {
                Text("Follows system").tag(ReduceMotionPolicy.followsSystem)
                Text("Always").tag(ReduceMotionPolicy.always)
                Text("Never").tag(ReduceMotionPolicy.never)
            }
            .accessibilityIdentifier("reduce-motion-picker")
        } header: {
            Text("Animation")
        } footer: {
            Text("Speed 6× plays a whole cycle in under nine seconds, which makes it easy to compare with a recording.")
        }
    }

    private var stillImageSection: some View {
        Section {
            SliderRow(title: "Phase", value: phase, range: 0...0.995, step: 0.005) {
                $0.formatted(.percent.precision(.fractionLength(0)))
            }
        } header: {
            Text("Still image")
        } footer: {
            Text("The frame shown when animation is off or Reduce Motion is on, and the one the animation starts from.")
        }
    }

    private var colourSection: some View {
        Section("Colour") {
            Picker("Palette", selection: $palette) {
                ForEach(PalettePreset.allCases) { Text($0.name).tag($0) }
            }
            .accessibilityIdentifier("palette-picker")
            SliderRow(title: "Intensity", value: $configuration.gradient.intensity, range: 0...2, step: 0.05) {
                $0.formatted(.percent.precision(.fractionLength(0)))
            }
            SliderRow(title: "Softness", value: $configuration.gradient.softness, range: 0.5...2, step: 0.05) {
                $0.formatted(.percent.precision(.fractionLength(0)))
            }
            ColorPicker("Base", selection: $configuration.palette.base, supportsOpacity: false)
            ForEach(configuration.palette.lights.indices, id: \.self) { index in
                ColorPicker("Light \(index + 1)", selection: $configuration.palette.lights[index], supportsOpacity: false)
            }
        }
    }

    private var vShapeSection: some View {
        Section("V") {
            Toggle("Show V", isOn: $configuration.vShape.isVisible)
                .accessibilityIdentifier("show-v-toggle")
            Group {
                SliderRow(title: "Opacity", value: $configuration.vShape.opacity, range: 0...1, step: 0.01) {
                    $0.formatted(.percent.precision(.fractionLength(0)))
                }
                SliderRow(title: "Scale", value: $configuration.vShape.scale, range: 0.5...1.5, step: 0.01) {
                    $0.formatted(.number.precision(.fractionLength(2))) + "×"
                }
                SliderRow(title: "Edge softness", value: $configuration.vShape.edgeSoftness, range: 0...0.04, step: 0.0005) {
                    ($0 * 100).formatted(.number.precision(.fractionLength(2))) + "%"
                }
            }
            .disabled(!configuration.vShape.isVisible)
        }
    }

    private var layoutSection: some View {
        Section {
            Picker("Scaling", selection: $configuration.scaling) {
                Text("Fit").tag(CompositionScaling.fit)
                Text("Fill width").tag(CompositionScaling.fillWidth)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Layout")
        } footer: {
            Text("The difference shows on short, wide screens, such as a phone in landscape.")
        }
    }

    /// The still phase as a plain number, for the slider.
    private var phase: Binding<Double> {
        Binding(
            get: { configuration.motion.staticPhase.fraction },
            set: { configuration.motion.staticPhase = AnimationPhase($0) }
        )
    }
}

/// A labelled slider that shows its value.
private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(format(value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step) {
                Text(title)
            }
            .accessibilityValue(format(value))
        }
    }
}
