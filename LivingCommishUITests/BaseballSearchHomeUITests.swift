import XCTest

@MainActor
final class BaseballSearchHomeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeIsSearchFirstAndPersonalized() {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["baseball-search-title"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.staticTexts["baseball-search-title"].label, "Search")
        XCTAssertFalse(app.staticTexts["BASEBALL LIVING HOST"].exists)
        XCTAssertTrue(app.textFields["baseball-search-field"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["baseball-search-button"].exists)
        XCTAssertTrue(app.otherElements["baseball-discovery-section"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["For You"].exists)
        XCTAssertTrue(app.staticTexts["Personalized for you"].exists)
        XCTAssertFalse(app.staticTexts["PROTOTYPE DATA"].exists)
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(
                    NSPredicate(
                        format: "label CONTAINS 'Michael' AND label CONTAINS 'Colorado Rockies'"
                    )
                )
                .firstMatch
                .exists
        )
        XCTAssertFalse(app.buttons["generate-reaction-button"].exists)
    }

    func testSearchBuildsVisualExperienceInsteadOfTranscript() {
        let app = launchApp()
        let field = app.textFields["baseball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("aaron judge")
        app.buttons["baseball-search-button"].tap()

        XCTAssertTrue(app.otherElements["baseball-results-overview"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.staticTexts["baseball-results-title"].label, "Aaron Judge")
        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-featured-result"].exists
        )
        XCTAssertTrue(
            app.staticTexts[
                "For Aaron Judge, power is the story. Contact quality is the first thing I’d inspect."
            ].exists
        )
        XCTAssertTrue(app.staticTexts["HOST OPINION"].exists)
        XCTAssertFalse(app.staticTexts["PROTOTYPE DATA"].exists)
        XCTAssertFalse(app.staticTexts["PROTOTYPE"].exists)
        XCTAssertTrue(app.buttons["baseball-results-close"].exists)
        XCTAssertFalse(app.staticTexts["LIVING COMMISH"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Aaron Judge grounded result"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testFavoriteTeamQuestionReturnsTheProfileFact() {
        let app = launchApp()
        let field = app.textFields["baseball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("What is my favorite team?")
        app.buttons["baseball-search-button"].tap()

        XCTAssertTrue(app.otherElements["baseball-results-overview"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["FACT"].exists)
        XCTAssertTrue(
            app.staticTexts["Your favorite team is the Colorado Rockies."].exists
        )
        XCTAssertFalse(app.staticTexts["HOST OPINION"].exists)
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--baseball-ui-testing"]
        app.launch()
        return app
    }
}
