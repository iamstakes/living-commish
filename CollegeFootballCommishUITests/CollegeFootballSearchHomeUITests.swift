import XCTest

final class CollegeFootballSearchHomeUITests: XCTestCase {
    @MainActor
    func testPersonalizedHomeLeadsWithCollegeFootball() {
        let app = personalizedApp()
        app.launch()

        let searchField = app.textFields["collegeFootball-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 8))

        let firstCard = app.buttons[
            "discovery-card-discovery-buffs-kickoff"
        ]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 8))
        XCTAssertTrue(firstCard.label.contains("Buffs vs. Nebraska"))
        XCTAssertFalse(firstCard.label.localizedCaseInsensitiveContains("baseball"))
    }

    @MainActor
    func testTravisHunterSearchOpensTwoWayGallery() {
        let app = personalizedApp()
        app.launch()

        let field = app.textFields["collegeFootball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("Travis Hunter")
        app.buttons["collegeFootball-search-button"].tap()

        let result = app.buttons["search-result-card"]
        XCTAssertTrue(result.waitForExistence(timeout: 8))
        XCTAssertTrue(result.label.contains("Travis Hunter"))
        XCTAssertTrue(result.label.contains("Colorado Buffaloes"))
        result.tap()

        XCTAssertTrue(
            app.staticTexts["THE TWO-WAY ARCHIVE"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.staticTexts["Travis Hunter"].exists)
        XCTAssertTrue(app.buttons["player-gallery-start-quiz"].exists)
    }

    @MainActor
    func testBuffsDailyDropOpensFullScreen() {
        let app = personalizedApp()
        app.launch()

        let next = app.buttons["host-presentation-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 8))
        next.tap()
        next.tap()
        next.tap()

        let drop = app.buttons[
            "discovery-card-discovery-daily-drop"
        ]
        XCTAssertTrue(drop.waitForExistence(timeout: 5))
        XCTAssertTrue(drop.label.contains("Buffs Quiz"))
        drop.tap()

        XCTAssertTrue(app.staticTexts["Meet the Buffs!"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Buffs Quiz"].exists)
    }

    @MainActor
    private func personalizedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--collegeFootball-ui-testing"]
        return app
    }
}
