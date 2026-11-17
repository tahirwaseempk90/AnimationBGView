import AnimationBGView
import SwiftUI

/// Holds the one configuration the whole app shares, so a change in the customization panel shows
/// everywhere. A configuration is a plain value, so `@State` is all the app needs.
struct RootView: View {
    private let options: LaunchOptions
    @State private var configuration: AnimatedBackgroundConfiguration
    @State private var palette: PalettePreset
    @State private var path: [LaunchOptions.Screen]
    @State private var isCustomizing: Bool

    init(options: LaunchOptions) {
        self.options = options
        _configuration = State(initialValue: options.initialConfiguration)
        _palette = State(initialValue: options.palette)
        switch options.screen {
        case .palettes, .layouts, .accessibility:
            _path = State(initialValue: [options.screen])
            _isCustomizing = State(initialValue: false)
        case .customize:
            _path = State(initialValue: [])
            _isCustomizing = State(initialValue: true)
        case .home:
            _path = State(initialValue: [])
            _isCustomizing = State(initialValue: false)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                configuration: configuration,
                showsContent: options.showsContent,
                customize: { isCustomizing = true },
                open: { path.append($0) }
            )
            .navigationDestination(for: LaunchOptions.Screen.self) { screen in
                switch screen {
                case .palettes:
                    PaletteGalleryView(configuration: $configuration, palette: $palette)
                case .layouts:
                    LayoutGalleryView(configuration: configuration)
                case .accessibility:
                    ReduceMotionView(configuration: configuration)
                case .home, .customize:
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $isCustomizing) {
            CustomizationPanel(
                configuration: $configuration,
                palette: $palette,
                defaults: (options.initialConfiguration, options.palette)
            )
            .presentationDetents([.fraction(0.5), .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
            .presentationBackground(.regularMaterial)
        }
    }
}
