import XCTest

@MainActor
final class LivingCommishUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsRendererAndIntelligenceIndicators() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.staticTexts["LIVING COMMISH"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'PNG fallback'")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Intelligence'")).firstMatch.exists)
        XCTAssertTrue(app.images.matching(NSPredicate(format: "label CONTAINS 'Commish character'")).firstMatch.waitForExistence(timeout: 12))
    }

    func testScenarioAndManualAnimationPipeline() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        let scenario = app.buttons["scenario-helmet"]
        XCTAssertTrue(scenario.waitForExistence(timeout: 12))
        scenario.tap()

        let bubble = app.staticTexts["response-bubble"]
        XCTAssertTrue(bubble.waitForExistence(timeout: 5))
        let initial = "Report the play. I’ll decide how much dignity survives."
        expectation(for: NSPredicate(format: "label != %@", initial), evaluatedWith: bubble)
        waitForExpectations(timeout: 30)

        app.swipeUp()
        app.swipeUp()
        let controls = app.buttons["Developer Controls"]
        XCTAssertTrue(controls.waitForExistence(timeout: 5))
        controls.tap()
        let wave = app.buttons["manual-wave"]
        XCTAssertTrue(wave.waitForExistence(timeout: 5))
        wave.tap()
    }

    func testDominantFinalSurfacesEmotionInCharacter() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        let field = app.textFields["fan-event-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        replaceText(
            "Argentina was embarrassed by Spain in the World Cup Final.",
            in: field
        )

        let generate = app.buttons["generate-reaction-button"]
        XCTAssertTrue(generate.waitForExistence(timeout: 3))
        generate.tap()

        let bubble = app.staticTexts["response-bubble"]
        XCTAssertTrue(bubble.waitForExistence(timeout: 5))
        expectation(
            for: NSPredicate(format: "label CONTAINS 'Argentina' AND label CONTAINS 'Spain'"),
            evaluatedWith: bubble
        )
        waitForExpectations(timeout: 15)

        XCTAssertTrue(app.staticTexts["Devastated"].exists)
        XCTAssertTrue(
            app.images
                .matching(NSPredicate(format: "label CONTAINS 'Sad Shrug animation'"))
                .firstMatch
                .waitForExistence(timeout: 5)
        )
    }

    func testRivalRecruitingUsesFanProfileAndSurfacesIrritation() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        let field = app.textFields["fan-event-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        replaceText("Ohio State just signed a 5-star recruit!", in: field)
        app.buttons["generate-reaction-button"].tap()

        let bubble = app.staticTexts["response-bubble"]
        XCTAssertTrue(bubble.waitForExistence(timeout: 5))
        expectation(
            for: NSPredicate(format: "label CONTAINS 'Ohio State' AND label CONTAINS 'Penn State'"),
            evaluatedWith: bubble
        )
        waitForExpectations(timeout: 15)

        XCTAssertTrue(app.staticTexts["Irritated"].exists)
        XCTAssertFalse(bubble.label.contains("group-chat evidence"))
    }

    func testWhiteoutAttendanceCelebratesAndCanBeRated() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        let field = app.textFields["fan-event-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        replaceText("I'm going to the Whiteout game!!!", in: field)
        app.buttons["generate-reaction-button"].tap()

        let bubble = app.staticTexts["response-bubble"]
        XCTAssertTrue(bubble.waitForExistence(timeout: 5))
        expectation(
            for: NSPredicate(format: "label CONTAINS 'Whiteout' AND label CONTAINS 'Penn State'"),
            evaluatedWith: bubble
        )
        waitForExpectations(timeout: 15)

        XCTAssertTrue(app.staticTexts["Electric"].exists)
        XCTAssertTrue(app.buttons["reaction-feedback-up"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reaction-feedback-correct"].waitForExistence(timeout: 5))
    }

    func testMemoryCanBeOpenedAndCleared() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let memory = app.buttons["memory-header-button"]
        XCTAssertTrue(memory.waitForExistence(timeout: 8))
        memory.tap()
        XCTAssertTrue(app.navigationBars["Fan Memory"].waitForExistence(timeout: 5))
        app.swipeUp()
        app.swipeUp()
        let forget = app.buttons["forget-everything-button"]
        XCTAssertTrue(forget.waitForExistence(timeout: 5))
        forget.tap()
        let confirm = app.sheets["Forget all local fan memory?"].buttons["Forget Everything"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()
    }

    func testEveryManualAnimationCanBeTriggered() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.images.matching(NSPredicate(format: "label CONTAINS 'Commish character'")).firstMatch.waitForExistence(timeout: 12))
        app.swipeUp()
        app.swipeUp()
        let controls = app.buttons["Developer Controls"]
        XCTAssertTrue(controls.waitForExistence(timeout: 5))
        controls.tap()

        let actions = [
            ("idle", "Idle"),
            ("pointRight", "Point Right"),
            ("sadShrug", "Sad Shrug"),
            ("wave", "Wave"),
            ("foamFinger", "Foam Finger"),
        ]

        for (identifier, displayName) in actions {
            let button = app.buttons["manual-\(identifier)"]
            if !button.isHittable { app.swipeUp() }
            XCTAssertTrue(button.waitForExistence(timeout: 4), "Missing manual control for \(displayName)")
            button.tap()
            let image = app.images.matching(NSPredicate(format: "label CONTAINS %@", "\(displayName) animation")).firstMatch
            XCTAssertTrue(image.waitForExistence(timeout: 3), "Character did not enter \(displayName)")
        }
    }

    private func replaceText(_ text: String, in field: XCUIElement) {
        field.tap()
        field.typeKey("a", modifierFlags: .command)
        field.typeKey(XCUIKeyboardKey.delete.rawValue, modifierFlags: [])
        field.typeText(text)
    }
}
