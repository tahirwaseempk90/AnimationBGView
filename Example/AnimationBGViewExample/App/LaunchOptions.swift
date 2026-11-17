import AnimationBGView
import Foundation

/// Settings passed as launch arguments, so the UI tests and the screenshot script can open any
/// screen in a known state. For example: `-screen palettes -phase 0.25 -speed 6`.
///
/// Launch arguments of the form `-key value` land in `UserDefaults`' argument domain, which is
/// never saved, so they only apply to that launch.
struct LaunchOptions {
    enum Screen: String, CaseIterable {
        case home, customize, palettes, layouts, accessibility
    }

    /// The screen to open.
    var screen: Screen = .home
    /// A still image at this phase, instead of animation. Used for repeatable screenshots.
    var stillPhase: Double?
    /// A playback speed. Recordings use a high speed to show a whole cycle in a few seconds.
    var speed: Double?
    /// The highest frame rate. Used to measure the cost of different rates.
    var frameRate: Double?
    /// The starting palette.
    var palette: PalettePreset = .reference
    /// Whether the home screen shows its text and buttons. `false` shows the bare background.
    var showsContent = true

    init(defaults: UserDefaults = .standard) {
        if let value = defaults.string(forKey: "screen"), let screen = Screen(rawValue: value) {
            self.screen = screen
        }
        if defaults.object(forKey: "phase") != nil {
            stillPhase = defaults.double(forKey: "phase")
        }
        if defaults.object(forKey: "speed") != nil {
            speed = defaults.double(forKey: "speed")
        }
        if defaults.object(forKey: "fps") != nil {
            frameRate = defaults.double(forKey: "fps")
        }
        if let value = defaults.string(forKey: "palette"), let palette = PalettePreset(rawValue: value) {
            self.palette = palette
        }
        if defaults.object(forKey: "content") != nil {
            showsContent = defaults.bool(forKey: "content")
        }
    }

    /// The configuration the app starts with.
    var initialConfiguration: AnimatedBackgroundConfiguration {
        var configuration = AnimatedBackgroundConfiguration.default
        configuration.palette = palette.palette
        if let speed { configuration.motion.speed = speed }
        if let frameRate { configuration.motion.frameRate = frameRate }
        if let stillPhase {
            configuration.motion.isEnabled = false
            configuration.motion.staticPhase = AnimationPhase(stillPhase)
        }
        return configuration
    }
}
