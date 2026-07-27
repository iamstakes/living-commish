import XCTest

@MainActor
final class BaseballSearchHomeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeIsSearchFirstAndPersonalized() {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["BASEBALL LIVING HOST"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["baseball-search-field"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["baseball-search-button"].exists)
        XCTAssertTrue(app.otherElements["baseball-discovery-section"].waitForExistence(timeout: 5))
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
        field.typeText("Aaron Judge")
        app.buttons["baseball-search-button"].tap()

        XCTAssertTrue(app.otherElements["baseball-results-overview"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Aaron Judge"].exists)
        XCTAssertTrue(app.staticTexts["HOST OPINION"].exists)
        XCTAssertTrue(app.buttons["baseball-results-close"].exists)
        XCTAssertFalse(app.staticTexts["LIVING COMMISH"].exists)
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
