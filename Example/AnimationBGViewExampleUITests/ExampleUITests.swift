import XCTest

final class ExampleUITests: ExampleUITestCase {
    @MainActor
    func testHomeScreenShowsContentOverTheBackground() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["home-title"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["customize-button"].isHittable, "The background doesn't block the controls over it")
        for screen in ["palettes", "layouts", "accessibility"] {
            XCTAssertTrue(app.buttons["\(screen)-button"].isHittable)
        }
    }

    @MainActor
    func testBackgroundGivesAssistiveTechnologiesNothingToRead() throws {
        let app = launch()
        XCTAssertTrue(app.staticTexts["home-title"].waitForExistence(timeout: timeout))
        // The example tags the background with an identifier so the test can find it. The query
        // tree still lists that as a structural container, but it must carry nothing VoiceOver
        // could read or focus: no label, no value, and no elements inside it.
        let background = app.descendants(matching: .any)["animated-background"]
        if background.exists {
            XCTAssertEqual(background.label, "")
            XCTAssertEqual((background.value as? String) ?? "", "")
            XCTAssertEqual(background.descendants(matching: .any).count, 0)
            XCTAssertEqual(background.elementType, .other)
        }
        // Every element VoiceOver can reach has a description.
        try app.performAccessibilityAudit(for: .sufficientElementDescription)
    }

    @MainActor
    func testCustomizationAppliesLiveAndResets() {
        let app = launch(["screen": "customize"])
        let form = app.collectionViews.firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: timeout))
        let toggle = app.switches["show-v-toggle"]
        scroll(form, toReveal: toggle)
        XCTAssertTrue(toggle.isHittable)
        XCTAssertEqual(toggle.value as? String, "1")
        let reset = app.buttons["reset-button"]
        XCTAssertFalse(reset.isEnabled, "Nothing to reset yet")

        flip(toggle)
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertTrue(reset.isEnabled)

        reset.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        XCTAssertFalse(reset.isEnabled)
    }

    @MainActor
    func testEveryScreenOpensFromHome() {
        let app = launch()
        XCTAssertTrue(app.buttons["palettes-button"].waitForExistence(timeout: timeout))
        let screens = [("palettes-button", "Palettes"), ("layouts-button", "Layouts"), ("accessibility-button", "Motion")]
        for (button, title) in screens {
            app.buttons[button].tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: timeout), title)
            app.navigationBars[title].buttons.firstMatch.tap()
            XCTAssertTrue(app.staticTexts["home-title"].waitForExistence(timeout: timeout))
        }
    }

    @MainActor
    func testChoosingAPaletteSelectsIt() {
        let app = launch(["screen": "palettes"])
        let mint = app.buttons["palette-mint"]
        XCTAssertTrue(mint.waitForExistence(timeout: timeout))
        XCTAssertFalse(mint.isSelected)
        mint.tap()
        XCTAssertTrue(mint.isSelected)
        XCTAssertFalse(app.buttons["palette-reference"].isSelected)
    }

    @MainActor
    func testRotationRelaysOutAndKeepsTheContentReachable() {
        let app = launch()
        let customize = app.buttons["customize-button"]
        XCTAssertTrue(customize.waitForExistence(timeout: timeout))
        // In portrait the content column is the screen width less its margins, at most 354 points
        // on these phones. In landscape it grows to its 600-point limit, so a wider button proves
        // the app laid itself out again, rather than the device rotating around an unchanged layout.
        XCTAssertLessThan(customize.frame.width, 400)

        XCUIDevice.shared.orientation = .landscapeLeft
        settle()
        XCTAssertTrue(app.staticTexts["home-title"].exists)
        XCTAssertTrue(customize.isHittable)
        XCTAssertGreaterThan(customize.frame.width, 400)

        XCUIDevice.shared.orientation = .portrait
        settle()
        XCTAssertTrue(customize.isHittable)
        XCTAssertLessThan(customize.frame.width, 400)
    }
}
