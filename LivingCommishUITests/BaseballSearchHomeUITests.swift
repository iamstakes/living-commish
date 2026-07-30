import XCTest

@MainActor
final class BaseballSearchHomeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstLaunchBuildsProfileInsideTheCommishStage() {
        let app = XCUIApplication()
        app.launchArguments = ["--baseball-onboarding-ui-testing"]
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-onboarding"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-onboarding-stage"].exists
        )
        XCTAssertTrue(app.otherElements["baseball-animated-host"].exists)
        let signedOutSearch = app.textFields["baseball-search-field"]
        XCTAssertTrue(signedOutSearch.waitForExistence(timeout: 5))
        XCTAssertEqual(signedOutSearch.placeholderValue, "Ask me anything MLB!")
        XCTAssertTrue(
            app.descendants(matching: .any)[
                "baseball-generic-chrome-background"
            ].exists
        )
        let onboardingThought = app.descendants(matching: .any)[
            "commish-live-thought"
        ]
        XCTAssertTrue(onboardingThought.waitForExistence(timeout: 5))
        XCTAssertTrue(onboardingThought.label.contains("Welcome!"))
        XCTAssertTrue(
            onboardingThought.label.contains(
                "your baseball companion"
            )
        )
        XCTAssertTrue(
            onboardingThought.label.contains(
                "Organized around your fandom!"
            )
        )
        let authenticationToggle = app.switches[
            "demo-authentication-toggle"
        ]
        XCTAssertTrue(authenticationToggle.waitForExistence(timeout: 5))
        XCTAssertEqual(authenticationToggle.value as? String, "Signed out")

        let teamCard = app.buttons["onboarding-team-card"]
        XCTAssertTrue(teamCard.waitForExistence(timeout: 5))
        teamCard.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-team-picker"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.staticTexts["team-picker-count"].exists)
        let rockies = app.buttons["team-choice-colorado-rockies"]
        XCTAssertTrue(rockies.waitForExistence(timeout: 5))
        rockies.tap()

        let pickerScreenshot = XCTAttachment(screenshot: app.screenshot())
        pickerScreenshot.name = "Commish card after Rockies selection"
        pickerScreenshot.lifetime = .keepAlways
        add(pickerScreenshot)

        let playerCard = app.buttons["onboarding-player-card"]
        XCTAssertTrue(playerCard.waitForExistence(timeout: 5))
        playerCard.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-player-picker"]
                .waitForExistence(timeout: 5)
        )
        let hunterGoodman = app.buttons["player-choice-696100"]
        XCTAssertTrue(
            hunterGoodman.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(hunterGoodman.label.contains("Hunter Goodman"))
        hunterGoodman.tap()

        let confirmationScreenshot = XCTAttachment(screenshot: app.screenshot())
        confirmationScreenshot.name = "Personalized Commish confirmation card"
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

        let host = app.otherElements["baseball-animated-host"]
        XCTAssertTrue(host.exists)
        host.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-profile-sheet"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["profile-favorite-team"]
                .label.contains("Colorado Rockies")
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["profile-favorite-player"]
                .label.contains("Hunter Goodman")
        )

        let homeScreenshot = XCTAttachment(screenshot: app.screenshot())
        homeScreenshot.name = "Commish-tap baseball profile"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)
    }

    func testSignedOutSearchStaysInsideTheGenericCommishStage() {
        let app = XCUIApplication()
        app.launchArguments = ["--baseball-onboarding-ui-testing"]
        app.launch()

        let field = app.textFields["baseball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("mike schmidt")
        app.buttons["baseball-search-button"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-results-stage"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.otherElements["baseball-animated-host"].exists)
        XCTAssertTrue(
            app.descendants(matching: .any)[
                "baseball-generic-chrome-background"
            ].exists
        )
        let resultCard = app.descendants(matching: .any)["search-result-card"]
        XCTAssertTrue(resultCard.exists)
        XCTAssertTrue(resultCard.label.contains("Mike Schmidt"))
        XCTAssertTrue(app.staticTexts["1 / 4"].exists)
        XCTAssertFalse(app.buttons["onboarding-team-card"].exists)

        let nextResult = app.buttons["search-results-next"]
        XCTAssertTrue(nextResult.exists)
        for (index, expectedText) in [
            "548 HR",
            "José Ramírez",
            "Class of 1995",
        ].enumerated() {
            nextResult.tap()
            expectation(
                for: NSPredicate(
                    format: "label CONTAINS %@",
                    expectedText
                ),
                evaluatedWith: resultCard
            )
            waitForExpectations(timeout: 3)
            XCTAssertTrue(app.staticTexts["\(index + 2) / 4"].exists)
            XCTAssertFalse(resultCard.label.contains("Judge"))
            XCTAssertFalse(resultCard.label.contains("Ohtani"))
        }

        let trayScreenshot = XCTAttachment(screenshot: app.screenshot())
        trayScreenshot.name = "Mike Schmidt Hall of Fame result card"
        trayScreenshot.lifetime = .keepAlways
        add(trayScreenshot)

        let clearSearch = app.buttons["clear-baseball-search"]
        XCTAssertTrue(clearSearch.waitForExistence(timeout: 3))
        clearSearch.tap()
        XCTAssertTrue(
            app.buttons["onboarding-team-card"].waitForExistence(timeout: 5)
        )
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
            "Ask me anything MLB!"
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
        let liveThought = app.descendants(matching: .any)[
            "commish-live-thought"
        ]
        XCTAssertTrue(liveThought.waitForExistence(timeout: 5))
        XCTAssertTrue(liveThought.label.contains("Brew crew"))
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
        expectation(
            for: NSPredicate(
                format: "label CONTAINS %@",
                "run differential is better than the A's"
            ),
            evaluatedWith: liveThought
        )
        waitForExpectations(timeout: 3)

        let standingsScreenshot = XCTAttachment(screenshot: app.screenshot())
        standingsScreenshot.name = "Dynamic standings presentation"
        standingsScreenshot.lifetime = .keepAlways
        add(standingsScreenshot)

        app.buttons["host-presentation-next"].tap()
        XCTAssertTrue(
            app.buttons["discovery-card-discovery-goodman-story"]
                .waitForExistence(timeout: 3)
        )
        expectation(
            for: NSPredicate(
                format: "label CONTAINS %@",
                "Good news? Goodman!"
            ),
            evaluatedWith: liveThought
        )
        waitForExpectations(timeout: 3)

        XCTAssertFalse(app.buttons["generate-reaction-button"].exists)
    }

    func testMikeSchmidtGalleryQuizAndCardCollectionFlow() {
        let app = launchApp()
        let field = app.textFields["baseball-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        field.typeText("mike schmidt")
        app.buttons["baseball-search-button"].tap()

        let resultCard = app.buttons["search-result-card"]
        XCTAssertTrue(resultCard.waitForExistence(timeout: 8))
        XCTAssertTrue(resultCard.label.contains("Mike Schmidt"))
        XCTAssertTrue(resultCard.label.contains("Philadelphia Phillies"))

        let trayScreenshot = XCTAttachment(screenshot: app.screenshot())
        trayScreenshot.name = "Mike Schmidt image card in search tray"
        trayScreenshot.lifetime = .keepAlways
        add(trayScreenshot)

        resultCard.tap()

        let galleryTitle = app.staticTexts["THE SCHMIDT ARCHIVE"]
        XCTAssertTrue(galleryTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Michael Jack Schmidt"].exists)

        let galleryScreenshot = XCTAttachment(screenshot: app.screenshot())
        galleryScreenshot.name = "Mike Schmidt archival image gallery"
        galleryScreenshot.lifetime = .keepAlways
        add(galleryScreenshot)

        let homeRun500Thumbnail = app.buttons[
            "player-gallery-thumbnail-schmidt-500"
        ]
        XCTAssertTrue(homeRun500Thumbnail.exists)
        homeRun500Thumbnail.tap()
        XCTAssertTrue(
            app.staticTexts["Home Run No. 500"]
                .waitForExistence(timeout: 3)
        )

        let milestoneScreenshot = XCTAttachment(
            screenshot: app.screenshot()
        )
        milestoneScreenshot.name = "Mike Schmidt 500th home run gallery image"
        milestoneScreenshot.lifetime = .keepAlways
        add(milestoneScreenshot)

        let startQuiz = app.buttons["player-gallery-start-quiz"]
        XCTAssertTrue(startQuiz.exists)
        startQuiz.tap()

        let startStories = app.buttons["daily-drop-start-stories"]
        XCTAssertTrue(startStories.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Meet Michael Jack."].exists)
        XCTAssertTrue(
            app.staticTexts[
                "Prove you know No. 20 and earn a LEGENDARY Mike Schmidt card."
            ].exists
        )

        let landingScreenshot = XCTAttachment(screenshot: app.screenshot())
        landingScreenshot.name = "Mike Schmidt Quiz landing"
        landingScreenshot.lifetime = .keepAlways
        add(landingScreenshot)

        startStories.tap()

        let storyCopy = app.descendants(matching: .any)[
            "daily-drop-story-copy"
        ]
        XCTAssertTrue(storyCopy.waitForExistence(timeout: 5))
        XCTAssertTrue(storyCopy.label.contains("Four Homers"))

        let storyButton = app.buttons["daily-drop-story-next"]
        XCTAssertTrue(storyButton.waitForExistence(timeout: 5))
        storyButton.tap()
        expectation(
            for: NSPredicate(
                format: "label CONTAINS %@",
                "Year He Had It All"
            ),
            evaluatedWith: storyCopy
        )
        waitForExpectations(timeout: 3)
        storyButton.tap()
        expectation(
            for: NSPredicate(
                format: "label CONTAINS %@",
                "No. 500 Won The Game"
            ),
            evaluatedWith: storyCopy
        )
        waitForExpectations(timeout: 3)
        storyButton.tap()

        for answerID in [
            "quiz-answer-schmidt-four-homer-game-1",
            "quiz-answer-schmidt-1980-homers-2",
            "quiz-answer-schmidt-career-homers-0",
        ] {
            let answer = app.buttons[answerID]
            XCTAssertTrue(
                answer.waitForExistence(timeout: 5),
                "Expected Mike Schmidt quiz answer \(answerID)"
            )
            answer.tap()

            let nextQuestion = app.buttons["quiz-next-button"]
            XCTAssertTrue(nextQuestion.waitForExistence(timeout: 4))
            nextQuestion.tap()
        }

        let pack = app.descendants(matching: .any)["daily-drop-pack"]
        XCTAssertTrue(pack.waitForExistence(timeout: 4))
        pack.tap()

        let claimReward = app.buttons["daily-drop-claim-reward"]
        XCTAssertTrue(claimReward.waitForExistence(timeout: 10))

        let rewardScreenshot = XCTAttachment(screenshot: app.screenshot())
        rewardScreenshot.name = "Legendary Mike Schmidt card reveal"
        rewardScreenshot.lifetime = .keepAlways
        add(rewardScreenshot)

        claimReward.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-profile-sheet"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts["Mike Schmidt added"].exists
        )
        let collectedCard = app.descendants(matching: .any)[
            "profile-sticker-sticker-mike-schmidt-hall-of-fame"
        ]
        XCTAssertTrue(collectedCard.exists)
        XCTAssertTrue(collectedCard.label.contains("LEGENDARY"))
        XCTAssertTrue(collectedCard.label.contains("Philadelphia Phillies"))
        XCTAssertFalse(
            app.descendants(matching: .any)["avatar-sticker-prompt"]
                .waitForExistence(timeout: 1)
        )

        let collectionScreenshot = XCTAttachment(
            screenshot: app.screenshot()
        )
        collectionScreenshot.name = "Mike Schmidt card added to collection"
        collectionScreenshot.lifetime = .keepAlways
        add(collectionScreenshot)

        app.buttons["baseball-profile-done"].tap()
        let resetRewards = app.buttons["demo-reset-stickers"]
        XCTAssertTrue(resetRewards.waitForExistence(timeout: 4))
        resetRewards.tap()
        XCTAssertFalse(resetRewards.waitForExistence(timeout: 2))
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

    func testThirdCardOpensMLBPlayerStoryDirectly() {
        let app = launchApp()
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

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

        XCTAssertTrue(
            safari.wait(for: .runningForeground, timeout: 8),
            "The third tile should open MLB.com directly"
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["player-story-full-screen"].exists
        )

        let screenshot = XCTAttachment(screenshot: safari.screenshot())
        screenshot.name = "Hunter Goodman MLB player story"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testDailyDropRunsQuizRipAndAddsStickerToProfile() {
        let app = launchApp()
        let nextButton = app.buttons["host-presentation-next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 8))

        for cardID in [
            "discovery-card-discovery-standings",
            "discovery-card-discovery-goodman-story",
            "discovery-card-discovery-daily-drop",
        ] {
            nextButton.tap()
            XCTAssertTrue(
                app.buttons[cardID].waitForExistence(timeout: 3),
                "Expected carousel card \(cardID)"
            )
        }

        let discoveryScreenshot = XCTAttachment(screenshot: app.screenshot())
        discoveryScreenshot.name = "Brand new Rockies Quiz discovery card"
        discoveryScreenshot.lifetime = .keepAlways
        add(discoveryScreenshot)

        app.buttons["discovery-card-discovery-daily-drop"].tap()

        let startButton = app.descendants(matching: .any)[
            "daily-drop-start-stories"
        ]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["BRAND NEW"].exists)
        XCTAssertTrue(app.staticTexts["Meet the Rox!"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "Win a RARE reward for taking today’s quiz."
            ].exists
        )

        let landingScreenshot = XCTAttachment(screenshot: app.screenshot())
        landingScreenshot.name = "Brand new Rockies Quiz landing"
        landingScreenshot.lifetime = .keepAlways
        add(landingScreenshot)

        startButton.tap()

        let storyCopy = app.descendants(matching: .any)[
            "daily-drop-story-copy"
        ]
        XCTAssertTrue(storyCopy.waitForExistence(timeout: 5))
        XCTAssertTrue(storyCopy.label.contains("Very First Rockie"))

        let firstStoryScreenshot = XCTAttachment(screenshot: app.screenshot())
        firstStoryScreenshot.name = "Rockies Quiz David Nied story"
        firstStoryScreenshot.lifetime = .keepAlways
        add(firstStoryScreenshot)

        let storyButton = app.descendants(matching: .any)[
            "daily-drop-story-next"
        ]
        XCTAssertTrue(storyButton.waitForExistence(timeout: 5))
        storyButton.tap()
        expectation(
            for: NSPredicate(
                format: "label CONTAINS %@",
                "80,227 Fans"
            ),
            evaluatedWith: storyCopy
        )
        waitForExpectations(timeout: 3)

        let secondStoryScreenshot = XCTAttachment(screenshot: app.screenshot())
        secondStoryScreenshot.name = "Rockies Quiz Mile High story"
        secondStoryScreenshot.lifetime = .keepAlways
        add(secondStoryScreenshot)

        storyButton.tap()
        expectation(
            for: NSPredicate(
                format: "label CONTAINS %@",
                "First Rockies Homer"
            ),
            evaluatedWith: storyCopy
        )
        waitForExpectations(timeout: 3)

        let thirdStoryScreenshot = XCTAttachment(screenshot: app.screenshot())
        thirdStoryScreenshot.name = "Rockies Quiz Dante Bichette story"
        thirdStoryScreenshot.lifetime = .keepAlways
        add(thirdStoryScreenshot)
        storyButton.tap()

        let correctAnswers = [
            "quiz-answer-rockies-first-selection-0",
            "quiz-answer-rockies-first-home-ballpark-1",
            "quiz-answer-rockies-first-home-run-2",
        ]
        for answerID in correctAnswers {
            let answer = app.descendants(matching: .any)[answerID]
            XCTAssertTrue(
                answer.waitForExistence(timeout: 5),
                "Expected quiz answer \(answerID)"
            )
            answer.tap()

            let nextQuestion = app.descendants(matching: .any)[
                "quiz-next-button"
            ]
            XCTAssertTrue(nextQuestion.waitForExistence(timeout: 4))
            nextQuestion.tap()
        }

        let pack = app.descendants(matching: .any)["daily-drop-pack"]
        XCTAssertTrue(pack.waitForExistence(timeout: 4))

        let earnedPackScreenshot = XCTAttachment(screenshot: app.screenshot())
        earnedPackScreenshot.name = "Baseball earned pack"
        earnedPackScreenshot.lifetime = .keepAlways
        add(earnedPackScreenshot)

        pack.tap()

        let claimReward = app.buttons["daily-drop-claim-reward"]
        XCTAssertTrue(claimReward.waitForExistence(timeout: 10))

        let stickerRevealScreenshot = XCTAttachment(
            screenshot: app.screenshot()
        )
        stickerRevealScreenshot.name = "Hunter Goodman sticker reveal"
        stickerRevealScreenshot.lifetime = .keepAlways
        add(stickerRevealScreenshot)

        claimReward.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball-profile-sheet"]
                .waitForExistence(timeout: 4)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["profile-sticker-collection"]
                .exists
        )
        let avatarPrompt = app.descendants(matching: .any)[
            "avatar-sticker-prompt"
        ]
        XCTAssertTrue(avatarPrompt.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Change your avatar?"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "Use your new Hunter Goodman sticker as your profile avatar?"
            ].exists
        )

        let promptScreenshot = XCTAttachment(screenshot: app.screenshot())
        promptScreenshot.name = "Use Hunter Goodman sticker as avatar prompt"
        promptScreenshot.lifetime = .keepAlways
        add(promptScreenshot)

        let useAvatar = app.buttons["avatar-prompt-use-sticker"]
        XCTAssertTrue(useAvatar.exists)
        useAvatar.tap()
        expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: avatarPrompt
        )
        waitForExpectations(timeout: 3)

        let collectedSticker = app.descendants(matching: .any)[
            "profile-sticker-sticker-hunter-goodman-three-homer"
        ]
        XCTAssertTrue(collectedSticker.exists)
        expectation(
            for: NSPredicate(format: "hittable == true"),
            evaluatedWith: collectedSticker
        )
        waitForExpectations(timeout: 5)
        let stickerAvatar = app.descendants(matching: .any)[
            "profile-avatar-sticker-hunter-goodman-three-homer"
        ]
        XCTAssertTrue(stickerAvatar.exists)
        XCTAssertTrue(stickerAvatar.isHittable)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Hunter Goodman sticker and profile avatar"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["baseball-profile-done"].tap()

        let selectedAvatarHost = app.otherElements[
            "baseball-animated-host"
        ]
        XCTAssertTrue(selectedAvatarHost.waitForExistence(timeout: 4))
        XCTAssertTrue(selectedAvatarHost.label.contains("Hunter Goodman"))
        XCTAssertEqual(
            selectedAvatarHost.value as? String,
            "Selected profile avatar"
        )

        let hostScreenshot = XCTAttachment(screenshot: app.screenshot())
        hostScreenshot.name = "Hunter Goodman replaces the Commish"
        hostScreenshot.lifetime = .keepAlways
        add(hostScreenshot)

        let resetRewards = app.buttons["demo-reset-stickers"]
        XCTAssertTrue(resetRewards.waitForExistence(timeout: 4))
        resetRewards.tap()
        expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: resetRewards
        )
        waitForExpectations(timeout: 3)
        XCTAssertTrue(
            selectedAvatarHost.label.contains(
                "Living Commish animated baseball guide"
            )
        )

        let profile = app.otherElements["baseball-animated-host"]
        XCTAssertTrue(profile.waitForExistence(timeout: 3))
        profile.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["profile-avatar-initial"]
                .waitForExistence(timeout: 4)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["profile-sticker-empty-state"]
                .exists
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
