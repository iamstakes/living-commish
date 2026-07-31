import XCTest
@testable import CollegeFootballCommish

@MainActor
final class CollegeFootballArchitectureTests: XCTestCase {
    func testProgramCatalogCentersColoradoAmongThirtyPrograms() {
        XCTAssertEqual(CollegeFootballTeamChoice.all.count, 30)
        XCTAssertEqual(Set(CollegeFootballTeamChoice.all.map(\.id)).count, 30)
        XCTAssertEqual(CollegeFootballTeamChoice.coloradoBuffaloes.espnID, 38)
        XCTAssertEqual(
            CollegeFootballTeamChoice.coloradoBuffaloes.fullName,
            "Colorado Buffaloes"
        )
        XCTAssertEqual(
            CollegeFootballTeamChoice.coloradoBuffaloes.division,
            "Big 12"
        )
    }

    func testPrototypeRosterStartsWithTravisHunter() async throws {
        let roster = try await PrototypeCollegeFootballRosterProvider().roster(
            for: .coloradoBuffaloes
        )

        XCTAssertEqual(roster.first?.fullName, "Travis Hunter")
        XCTAssertEqual(roster.first?.position, "Cornerback / Wide Receiver")
        XCTAssertEqual(roster.first?.jerseyNumber, "12")
        XCTAssertTrue(roster.contains { $0.fullName == "Rashaan Salaam" })
    }

    func testUITestProfileIsPersonalizedForCollegeFootball() {
        let suiteName = "CollegeFootballUITestProfile.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = CollegeFootballOnboardingState(
            defaults: defaults,
            arguments: ["--collegeFootball-ui-testing"],
            rosterProvider: PrototypeCollegeFootballRosterProvider()
        )

        XCTAssertTrue(state.isPersonalizedExperienceActive)
        XCTAssertEqual(state.selectedTeam?.fullName, "Colorado Buffaloes")
        XCTAssertEqual(state.selectedPlayer?.fullName, "Travis Hunter")
        XCTAssertEqual(state.profileSnapshot.rivalTeams, ["Nebraska Cornhuskers"])
    }

    func testDeterministicInterpreterRecognizesCoreCollegeFootballQueries() async throws {
        let interpreter = DeterministicCollegeFootballQueryInterpreter()
        let profile = MockMichaelProfile.value
        let cases: [(String, CollegeFootballSearchIntent, String?)] = [
            ("Travis Hunter", .entityLookup, "player-travis-hunter"),
            ("Shedeur Sanders", .entityLookup, "player-shedeur-sanders"),
            ("Colorado Buffs", .teamLookup, "team-colorado-buffaloes"),
            ("Compare Travis Hunter and Ashton Jeanty", .playerComparison, "player-travis-hunter"),
            ("What is Colorado’s playoff path?", .standingsImpact, "team-colorado-buffaloes"),
            ("Games this weekend", .gamesTonight, nil),
        ]

        for (text, expectedIntent, firstEntityID) in cases {
            let query = try await interpreter.interpret(text, profile: profile)
            XCTAssertEqual(query.intent, expectedIntent, text)
            XCTAssertEqual(query.entities.first?.id, firstEntityID, text)
        }
    }

    func testHunterSearchBuildsGalleryPerformanceInsightsAndQuiz() async throws {
        let profile = MockMichaelProfile.value
        let query = try await DeterministicCollegeFootballQueryInterpreter()
            .interpret("Travis Hunter", profile: profile)
        let plan = DefaultCollegeFootballSearchPlanner().plan(for: query)
        let snapshot = try await MockCollegeFootballDataService().fetch(
            plan: plan,
            profile: profile
        )

        guard let hunter = snapshot.modules.compactMap({ module in
            if case .player(let player) = module { return player }
            return nil
        }).first else {
            return XCTFail("Expected a Travis Hunter player result")
        }

        XCTAssertEqual(hunter.id, "travis-hunter")
        XCTAssertEqual(hunter.gallery.count, 4)
        XCTAssertEqual(hunter.quiz?.title, "Travis Hunter Quiz")
        XCTAssertEqual(hunter.quiz?.rewardSticker, CollegeFootballStickerCatalog.travisHunter)
        XCTAssertTrue(snapshot.modules.contains { module in
            if case .performance = module { return true }
            return false
        })
        XCTAssertEqual(snapshot.modules.compactMap { module in
            if case .playerInsight(let insight) = module { return insight }
            return nil
        }.count, 3)
    }

    func testHunterAndJeantyComparisonStaysOnPremise() async throws {
        let profile = MockMichaelProfile.value
        let query = try await DeterministicCollegeFootballQueryInterpreter()
            .interpret(
                "Compare Travis Hunter and Ashton Jeanty",
                profile: profile
            )
        let plan = DefaultCollegeFootballSearchPlanner().plan(for: query)
        let snapshot = try await MockCollegeFootballDataService().fetch(
            plan: plan,
            profile: profile
        )

        let players = snapshot.modules.compactMap { module -> String? in
            if case .player(let player) = module { return player.name }
            return nil
        }
        XCTAssertEqual(players, ["Travis Hunter", "Ashton Jeanty"])
        XCTAssertTrue(snapshot.modules.contains { module in
            if case .comparison(let comparison) = module {
                return comparison.id == "hunter-jeanty-comparison"
            }
            return false
        })
    }

    func testDiscoveryDeckContainsSixCollegeFootballCards() async throws {
        let cards = try await MockCollegeFootballDiscoveryService().cards(
            for: MockMichaelProfile.value
        )

        XCTAssertEqual(cards.count, 6)
        XCTAssertEqual(cards.first?.id, "discovery-buffs-kickoff")
        XCTAssertEqual(cards.first?.title, "Buffs vs. Nebraska at Folsom")
        XCTAssertEqual(
            cards.first(where: { $0.playerStory != nil })?
                .playerStory?.playerName,
            "Travis Hunter"
        )
        XCTAssertEqual(
            cards.first(where: { $0.dailyDrop != nil })?.dailyDrop?.title,
            "Buffs Quiz"
        )
    }

    func testBuffsQuizIsThreeQuestionsAndRewardsSalaam() {
        let quiz = CollegeFootballDailyDropCatalog.buffsHistoryQuiz

        XCTAssertEqual(quiz.stories.count, 3)
        XCTAssertEqual(quiz.questions.count, 3)
        XCTAssertEqual(quiz.rewardSticker, CollegeFootballStickerCatalog.rashaanSalaam)
        XCTAssertEqual(quiz.rewardSticker.rarity, .rare)
        XCTAssertEqual(
            quiz.questions.map(\.correctAnswerIndex),
            [1, 1, 2]
        )
    }

    func testHunterQuizIsThreeQuestionsAndRewardsLegendaryCard() {
        let quiz = CollegeFootballDailyDropCatalog.travisHunterQuiz

        XCTAssertEqual(quiz.stories.count, 3)
        XCTAssertEqual(quiz.questions.count, 3)
        XCTAssertEqual(quiz.rewardSticker, CollegeFootballStickerCatalog.travisHunter)
        XCTAssertEqual(quiz.rewardSticker.rarity, .legendary)
        XCTAssertEqual(
            quiz.questions.map(\.correctAnswerIndex),
            [1, 2, 0]
        )
    }
}
