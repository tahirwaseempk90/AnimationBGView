import XCTest

/// Captures every screen for the README and for visual review. The attachments are kept in the
/// test result bundle, where `Scripts/export-screenshots.py` collects them.
///
/// Still images at a fixed phase make the screenshots repeatable. `Scripts/capture-screenshots.sh`
/// runs these on several simulators.
final class ScreenshotTests: ExampleUITestCase {
    private let phase = "0"

    @MainActor
    func testCaptureScreens() {
        let scenarios: [(name: String, arguments: [String: String])] = [
            ("home", ["phase": phase]),
            ("background", ["phase": phase, "content": "NO"]),
            ("customize", ["phase": phase, "screen": "customize"]),
            ("palettes", ["phase": phase, "screen": "palettes"]),
            ("layouts", ["phase": phase, "screen": "layouts"]),
            ("motion", ["phase": phase, "screen": "accessibility"])
        ]
        for scenario in scenarios {
            let app = launch(scenario.arguments)
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
            settle(1.5)
            attachScreenshot(named: scenario.name, of: app)
            app.terminate()
        }
    }

    @MainActor
    func testCaptureMoreLayouts() {
        let app = launch(["phase": phase, "screen": "layouts"])
        let list = app.scrollViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: timeout))
        settle()
        // Past the portrait sample, to the landscape ones.
        let start = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let end = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        start.press(forDuration: 0.1, thenDragTo: end)
        settle(1.5)
        attachScreenshot(named: "layouts-landscape", of: app)
        app.terminate()
    }

    @MainActor
    func testCapturePhasesThroughTheCycle() {
        for quarter in 0..<4 {
            let app = launch(["phase": "\(Double(quarter) / 4)", "content": "NO"])
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
            settle(1)
            attachScreenshot(named: "phase-\(quarter * 25)", of: app)
            app.terminate()
        }
    }

    @MainActor
    func testCaptureLandscape() {
        let app = launch(["phase": phase])
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: timeout))
        XCUIDevice.shared.orientation = .landscapeLeft
        settle(1.5)
        attachScreenScreenshot(named: "home-landscape")
        app.terminate()

        let bare = launch(["phase": phase, "content": "NO"])
        XCTAssertTrue(bare.wait(for: .runningForeground, timeout: timeout))
        XCUIDevice.shared.orientation = .landscapeLeft
        settle(1.5)
        attachScreenScreenshot(named: "background-landscape")
        bare.terminate()
    }
}
