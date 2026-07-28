import XCTest

@MainActor
final class BaseballSearchHomeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstLaunchSelectsRockiesAndEntersThemedHome() {
        let app = XCUIApplication()
        app.launchArguments = ["--baseball-onboarding-ui-testing"]
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-onboarding"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.staticTexts["onboarding-team-title"].exists)

        let rockies = app.buttons["onboarding-team-colorado-rockies"]
        XCTAssertTrue(rockies.waitForExistence(timeout: 5))
        XCTAssertEqual(rockies.value as? String, "Not selected")
        rockies.tap()
        XCTAssertEqual(rockies.value as? String, "Selected")

        let pickerScreenshot = XCTAttachment(screenshot: app.screenshot())
        pickerScreenshot.name = "Rockies out-of-box team selection"
        pickerScreenshot.lifetime = .keepAlways
        add(pickerScreenshot)

        let continueButton = app.buttons["onboarding-continue"]
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["onboarding-confirmation"]
                .waitForExistence(timeout: 4)
        )
        XCTAssertTrue(
            app.staticTexts["onboarding-confirmation-title"].exists
        )

        let confirmationScreenshot = XCTAttachment(screenshot: app.screenshot())
        confirmationScreenshot.name = "Rockies onboarding confirmation"
        confirmationScreenshot.lifetime = .keepAlways
        add(confirmationScreenshot)

        app.buttons["onboarding-finish"].tap()
        XCTAssertTrue(
            app.textFields["baseball-search-field"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["rockies-chrome-background"].exists
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["baseball-onboarding"].exists
        )

        let homeScreenshot = XCTAttachment(screenshot: app.screenshot())
        homeScreenshot.name = "Rockies themed personalized home"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)
    }

    func testHomeIsSearchFirstAndPersonalized() {
        let app = launchApp()

        XCTAssertFalse(app.staticTexts["baseball-search-title"].exists)
        XCTAssertFalse(app.staticTexts["BASEBALL LIVING HOST"].exists)
        XCTAssertFalse(
            app.staticTexts[
                "Players, teams, games, history, and the moments that matter to you."
            ].exists
        )
        let searchField = app.textFields["baseball-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertEqual(
            searchField.placeholderValue,
            "Ask me anything about baseball"
        )
        XCTAssertTrue(app.buttons["baseball-search-button"].exists)
        let presentationStage = app.otherElements["baseball-discovery-section"]
        XCTAssertTrue(presentationStage.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["For You"].exists)
        XCTAssertFalse(app.staticTexts["Personalized for you"].exists)
        XCTAssertFalse(app.staticTexts["PROTOTYPE DATA"].exists)
        XCTAssertFalse(app.staticTexts["QUICK SEARCHES"].exists)
        XCTAssertFalse(app.buttons["quick-search-aaron-judge"].exists)
        XCTAssertFalse(
            app.descendants(matching: .any)["baseball-profile-circle"].exists
        )
        XCTAssertGreaterThanOrEqual(
            searchField.frame.minY,
            presentationStage.frame.minY
        )
        XCTAssertLessThanOrEqual(
            searchField.frame.maxY,
            presentationStage.frame.maxY
        )
        let firstCard = app.buttons["discovery-card-discovery-rockies-tonight"]
        XCTAssertTrue(firstCard.exists)
        XCTAssertTrue(firstCard.label.contains("Final. Rockies 2, Brewers 11"))
        XCTAssertGreaterThan(firstCard.frame.width, 250)
        XCTAssertGreaterThan(firstCard.frame.midY, presentationStage.frame.midY)
        XCTAssertGreaterThan(
            firstCard.frame.minY,
            presentationStage.frame.minY + 180
        )
        XCTAssertTrue(firstCard.isHittable)
        let nextCardButton = app.buttons["host-presentation-next"]
        XCTAssertTrue(nextCardButton.exists)
        XCTAssertLessThan(
            app.windows.firstMatch.frame.maxY - nextCardButton.frame.maxY,
            80
        )
        let host = app.otherElements["baseball-animated-host"]
        XCTAssertTrue(host.exists)
        XCTAssertGreaterThan(host.frame.height, 450)
        XCTAssertFalse(
            app.descendants(matching: .any)
                .matching(
                    NSPredicate(
                        format: "label CONTAINS 'Michael' AND label CONTAINS 'Colorado Rockies'"
                    )
                )
                .firstMatch
                .exists
        )
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Layered discovery presentation"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["host-presentation-next"].tap()
        let standingsCard = app.buttons["discovery-card-discovery-standings"]
        XCTAssertTrue(standingsCard.waitForExistence(timeout: 3))
        XCTAssertTrue(standingsCard.label.contains("3–7"))
        XCTAssertTrue(standingsCard.label.contains("Athletics"))
        XCTAssertTrue(standingsCard.label.contains("San Diego Padres"))

        let standingsScreenshot = XCTAttachment(screenshot: app.screenshot())
        standingsScreenshot.name = "Dynamic standings presentation"
        standingsScreenshot.lifetime = .keepAlways
        add(standingsScreenshot)

        XCTAssertFalse(app.buttons["generate-reaction-button"].exists)
    }

    func testSearchBuildsVisualExperienceInsteadOfTranscript() {
        let app = launchApp()
        let field = app.textFields["baseball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("mike schmidt")
        app.buttons["baseball-search-button"].tap()

        let resultsStage = app.descendants(matching: .any)[
            "baseball-results-stage"
        ]
        XCTAssertTrue(resultsStage.waitForExistence(timeout: 8))
        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-results-deck"].exists
        )
        let resultCard = app.descendants(matching: .any)["search-result-card"]
        XCTAssertTrue(resultCard.exists)
        XCTAssertTrue(resultCard.label.contains("Mike Schmidt"))
        XCTAssertTrue(resultCard.label.contains("Philadelphia Phillies"))
        XCTAssertGreaterThan(
            app.otherElements["baseball-animated-host"].frame.height,
            450
        )
        XCTAssertTrue(app.textFields["baseball-search-field"].exists)
        XCTAssertFalse(app.otherElements["baseball-results-overview"].exists)
        XCTAssertFalse(app.otherElements["result-presentation-stage"].exists)
        XCTAssertFalse(app.otherElements["baseball-search-error"].exists)
        XCTAssertFalse(app.staticTexts["PROTOTYPE DATA"].exists)
        XCTAssertFalse(app.staticTexts["PROTOTYPE"].exists)
        XCTAssertFalse(app.buttons["baseball-results-close"].exists)
        XCTAssertFalse(app.staticTexts["LIVING COMMISH"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Mike Schmidt result in Commish stage"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testSearchKeyboardCanBeDismissedWithoutSubmitting() {
        let app = launchApp()
        let field = app.textFields["baseball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("mike")

        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        let dismissButton = app.buttons["dismiss-search-keyboard"]
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 3))
        dismissButton.tap()

        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        XCTAssertTrue(
            app.buttons["discovery-card-discovery-rockies-tonight"].exists
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["baseball-results-stage"].exists
        )
    }

    func testUnknownSearchStaysInsideTheCommishStage() {
        let app = launchApp()
        let field = app.textFields["baseball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("tell me something")
        app.buttons["baseball-search-button"].tap()

        let failureCard = app.descendants(matching: .any)[
            "baseball-search-error"
        ]
        XCTAssertTrue(failureCard.waitForExistence(timeout: 8))
        XCTAssertTrue(
            app.descendants(matching: .any)["search-presentation-stage"].exists
        )
        XCTAssertTrue(app.otherElements["baseball-animated-host"].exists)
        XCTAssertTrue(app.textFields["baseball-search-field"].exists)
        XCTAssertFalse(app.staticTexts["TRY ONE OF THESE"].exists)
        XCTAssertFalse(app.otherElements["baseball-results-overview"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Unknown search remains in Commish stage"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testThirdCardExpandsHunterGoodmanStoryFullScreen() {
        let app = launchApp()

        let nextButton = app.buttons["host-presentation-next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 8))
        nextButton.tap()
        XCTAssertTrue(
            app.buttons["discovery-card-discovery-standings"]
                .waitForExistence(timeout: 3)
        )
        nextButton.tap()

        let storyCard = app.buttons["discovery-card-discovery-goodman-story"]
        XCTAssertTrue(storyCard.waitForExistence(timeout: 3))
        XCTAssertTrue(storyCard.label.contains("Hunter Goodman"))
        XCTAssertTrue(storyCard.label.contains("30th homer"))
        storyCard.tap()

        let fullScreenStory = app.descendants(matching: .any)[
            "player-story-full-screen"
        ]
        XCTAssertTrue(
            fullScreenStory.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["player-story-title"].exists)
        XCTAssertTrue(app.staticTexts["Best of the Last 10"].exists)
        XCTAssertTrue(
            app.staticTexts["His 30th homer was his third of the game"].exists
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["player-story-source-link"].exists
        )

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Hunter Goodman full-screen player story"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["Close player story"].tap()
        XCTAssertTrue(
            app.otherElements["baseball-discovery-section"]
                .waitForExistence(timeout: 3)
        )
    }

    func testFavoriteTeamQuestionReturnsTheProfileFact() {
        let app = launchApp()
        let field = app.textFields["baseball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("What is my favorite team?")
        app.buttons["baseball-search-button"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-results-stage"]
                .waitForExistence(timeout: 8)
        )
        let resultCard = app.descendants(matching: .any)["search-result-card"]
        XCTAssertTrue(resultCard.exists)
        XCTAssertTrue(resultCard.label.contains("Colorado Rockies"))
        XCTAssertTrue(app.otherElements["baseball-animated-host"].exists)
        XCTAssertFalse(app.otherElements["baseball-results-overview"].exists)
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--baseball-ui-testing"]
        app.launch()
        return app
    }
}
