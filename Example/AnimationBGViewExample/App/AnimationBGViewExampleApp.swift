import SwiftUI

@main
struct AnimationBGViewExampleApp: App {
    private let options = LaunchOptions()

    var body: some Scene {
        WindowGroup {
            RootView(options: options)
        }
    }
}
