import XCTest

/// Launches the example app with launch arguments, and attaches screenshots.
///
/// UI automation APIs belong to the main actor, so every test and helper that touches them is
/// marked `@MainActor`.
class ExampleUITestCase: XCTestCase {
    let timeout: TimeInterval = 15

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        // A test that fails while rotated mustn't leave the next one in landscape.
        await MainActor.run { XCUIDevice.shared.orientation = .portrait }
        try await super.tearDown()
    }

    /// Launches the app with `-key value` arguments, which it reads from `UserDefaults`.
    @MainActor
    @discardableResult
    func launch(_ arguments: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments.sorted { $0.key < $1.key }.flatMap { ["-\($0.key)", $0.value] }
        app.launch()
        return app
    }

    @MainActor
    func attachScreenshot(named name: String, of app: XCUIApplication) {
        attach(app.screenshot(), named: name)
    }

    /// A screenshot of the whole screen, in the display's native orientation.
    ///
    /// In landscape, `XCUIApplication.screenshot()` crops the unrotated display to the rotated
    /// window, which cuts off most of the screen. The whole display is complete, and
    /// `Scripts/capture-screenshots.sh` turns it upright.
    @MainActor
    func attachScreenScreenshot(named name: String) {
        attach(XCUIScreen.main.screenshot(), named: name)
    }

    @MainActor
    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Waits for animations, such as a navigation push or a sheet, to finish.
    @MainActor
    func settle(_ seconds: TimeInterval = 1) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    /// Drags a scrolling container upward until an element is on screen. Lists create rows
    /// lazily, so an element further down may not exist until it's been scrolled to.
    ///
    /// The drag runs down the container's left margin: a swipe from the middle would start on a
    /// slider, which takes the touch, and nothing would scroll.
    @MainActor
    func scroll(_ container: XCUIElement, toReveal element: XCUIElement, maximumDrags: Int = 12) {
        var drags = 0
        while !(element.exists && element.isHittable), drags < maximumDrags {
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.85))
            let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: 0.3))
            start.press(forDuration: 0.1, thenDragTo: end)
            settle(0.5)
            drags += 1
        }
    }

    /// Taps a toggle's switch, which sits at the trailing end of its row.
    @MainActor
    func flip(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
    }
}
