import SwiftUI
@preconcurrency import UIKit
import XCTest
@testable import LivingCommish

@MainActor
final class BaseballArchitectureTests: XCTestCase {
    func testBaseballSearchIsDefaultAndLegacyLaunchModesRemainExplicit() {
        XCTAssertEqual(AppExperienceMode.resolve(arguments: []), .baseballSearch)
        XCTAssertEqual(
            AppExperienceMode.resolve(arguments: ["--baseball-ui-testing"]),
            .baseballSearch
        )
        XCTAssertEqual(
            AppExperienceMode.resolve(
                arguments: ["--baseball-onboarding-ui-testing"]
            ),
            .baseballSearch
        )
        XCTAssertEqual(
            AppExperienceMode.resolve(arguments: ["--legacy-commish"]),
            .livingCommish
        )
        XCTAssertEqual(
            AppExperienceMode.resolve(arguments: ["--ui-testing"]),
            .livingCommish
        )
        XCTAssertEqual(
            AppExperienceMode.resolve(arguments: ["--ui-testing", "--baseball-ui-testing"]),
            .baseballSearch
        )
    }

    func testBaseballOnboardingPersistsTeamPlayerAndAuthentication() async {
        let suiteName = "BaseballOnboardingStateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let firstLaunch = BaseballOnboardingState(
            defaults: defaults,
            arguments: [],
            rosterProvider: PrototypeBaseballRosterProvider()
        )
        XCTAssertFalse(firstLaunch.isSignedIn)
        XCTAssertFalse(firstLaunch.hasCompletedOnboarding)
        XCTAssertNil(firstLaunch.selectedTeam)

        firstLaunch.setSignedIn(true)
        firstLaunch.selectTeam(.coloradoRockies)
        XCTAssertEqual(firstLaunch.selectedTeam?.name, "Rockies")
        await firstLaunch.loadRoster()
        let hunterGoodman = firstLaunch.roster.first {
            $0.fullName == "Hunter Goodman"
        }
        XCTAssertNotNil(hunterGoodman)
        firstLaunch.selectPlayer(hunterGoodman!)
        XCTAssertTrue(firstLaunch.complete())

        let returningLaunch = BaseballOnboardingState(
            defaults: defaults,
            arguments: [],
            rosterProvider: PrototypeBaseballRosterProvider()
        )
        XCTAssertTrue(returningLaunch.isSignedIn)
        XCTAssertTrue(returningLaunch.hasCompletedOnboarding)
        XCTAssertEqual(
            returningLaunch.selectedTeamID,
            BaseballTeamChoice.coloradoRockies.id
        )
        XCTAssertEqual(
            returningLaunch.selectedPlayer?.fullName,
            "Hunter Goodman"
        )
        XCTAssertEqual(
            returningLaunch.profileSnapshot.favoriteTeam,
            "Colorado Rockies"
        )
        XCTAssertEqual(
            returningLaunch.profileSnapshot.favoritePlayers,
            ["Hunter Goodman"]
        )
    }

    func testDemoSignOutPreservesPersonalizationForSignBackIn() {
        let suiteName = "BaseballAuthStateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let state = BaseballOnboardingState(
            defaults: defaults,
            arguments: ["--baseball-ui-testing"],
            rosterProvider: PrototypeBaseballRosterProvider()
        )

        XCTAssertTrue(state.isSignedIn)
        XCTAssertTrue(state.hasCompletedOnboarding)
        state.setSignedIn(false)
        XCTAssertFalse(state.isSignedIn)
        XCTAssertEqual(state.selectedTeam?.fullName, "Colorado Rockies")
        XCTAssertEqual(state.selectedPlayer?.fullName, "Hunter Goodman")

        state.setSignedIn(true)
        XCTAssertTrue(state.isSignedIn)
        XCTAssertTrue(state.hasCompletedOnboarding)
    }

    func testTeamCatalogContainsAllThirtyMLBClubs() {
        XCTAssertEqual(BaseballTeamChoice.all.count, 30)
        XCTAssertEqual(Set(BaseballTeamChoice.all.map(\.id)).count, 30)
        XCTAssertTrue(
            BaseballTeamChoice.all.contains {
                $0.fullName == "Colorado Rockies" && $0.mlbID == 115
            }
        )
    }

    func testMockMichaelProfileIsRichAndIsolated() {
        let michael = MockMichaelProfile.value

        XCTAssertEqual(michael.name, "Michael")
        XCTAssertEqual(michael.favoriteTeam, "Colorado Rockies")
        XCTAssertTrue(michael.interests.contains(.emergingPlayers))
        XCTAssertTrue(michael.interests.contains(.playoffRaces))
        XCTAssertTrue(michael.interests.contains(.condensedGames))
        XCTAssertGreaterThanOrEqual(michael.stadiumVisits.count, 3)
        XCTAssertTrue(michael.frequentSearchThemes.contains("Wild Card implications"))
    }

    func testInterpreterRecognizesPrioritySearches() async throws {
        let interpreter = DeterministicBaseballQueryInterpreter()
        let cases: [(String, BaseballSearchIntent)] = [
            ("What is my favorite team?", .favoriteTeam),
            ("Which team do I support?", .favoriteTeam),
            ("Who is my favorite player?", .favoritePlayer),
            ("Aaron Judge", .entityLookup),
            ("Mike Schmidt", .entityLookup),
            ("Rockies", .teamLookup),
            ("Games tonight", .gamesTonight),
            ("Who should I watch?", .playerRecommendation),
            ("Compare Judge and Ohtani", .playerComparison),
            ("Why isn't Ohtani pitching?", .availabilityExplanation),
            ("What did I miss yesterday?", .missedGamesRecap),
            ("How does tonight affect the Wild Card?", .standingsImpact),
            ("When was my last Rockies game?", .personalAttendanceHistory),
        ]

        for (rawQuery, expectedIntent) in cases {
            let result = try await interpreter.interpret(
                rawQuery,
                profile: MockMichaelProfile.value
            )
            XCTAssertEqual(result.intent, expectedIntent, rawQuery)
        }
    }

    func testAppleStructuredInterpretationMapsToGroundedSearchQuery() {
        let interpretation = AppleBaseballInterpretation(
            intent: .entityLookup,
            entities: [
                AppleBaseballEntity(
                    canonicalName: "Schmidt",
                    kind: .player
                )
            ],
            timeScope: .unspecified,
            requiresPersonalHistory: false
        )

        let query = AppleFoundationModelsBaseballQueryInterpreter.makeQuery(
            rawText: "mike schmidt",
            interpretation: interpretation,
            profile: MockMichaelProfile.value
        )

        XCTAssertEqual(query.intent, .entityLookup)
        XCTAssertEqual(query.entities.first?.id, "player-mike-schmidt")
        XCTAssertEqual(query.entities.first?.canonicalName, "Mike Schmidt")
        XCTAssertEqual(query.timeScope, .unspecified)
        XCTAssertNil(query.ambiguity)
    }

    func testAppleInterpretationDecodesJSONWithoutDependingOnGuidedGeneration() throws {
        let interpretation = try AppleFoundationModelsBaseballQueryInterpreter
            .decodeInterpretation(
                """
                ```json
                {"intent":"teamLookup","entities":[{"canonicalName":"Rockies","kind":"team"}],"timeScope":"today","requiresPersonalHistory":false}
                ```
                """
            )

        XCTAssertEqual(interpretation.intent, .teamLookup)
        XCTAssertEqual(interpretation.entities.first?.canonicalName, "Rockies")
        XCTAssertEqual(interpretation.entities.first?.kind, .team)
        XCTAssertEqual(interpretation.timeScope, .today)
        XCTAssertFalse(interpretation.requiresPersonalHistory)
    }

    func testAppleBaseballInterpreterDiagnostic() async throws {
        let interpreter = AppleFoundationModelsBaseballQueryInterpreter()
        guard interpreter.isAvailable else {
            throw XCTSkip(
                "Apple Foundation Models is unavailable in this test environment."
            )
        }

        let query: BaseballSearchQuery
        do {
            query = try await interpreter.interpret(
                "mike schmidt",
                profile: MockMichaelProfile.value
            )
        } catch {
            throw XCTSkip(
                "The simulator's Apple model runtime is incomplete: \(error.localizedDescription)"
            )
        }

        XCTAssertEqual(query.intent, .entityLookup)
        XCTAssertEqual(query.entities.first?.canonicalName, "Mike Schmidt")
    }

    func testFavoriteTeamQuestionReturnsAGroundedProfileFact() async throws {
        let profile = MockMichaelProfile.value
        let interpreter = DeterministicBaseballQueryInterpreter()
        let query = try await interpreter.interpret(
            "What is my favorite team?",
            profile: profile
        )
        let plan = DefaultBaseballSearchPlanner().plan(for: query)
        let snapshot = try await MockBaseballDataService().fetch(
            plan: plan,
            profile: profile
        )
        let editorial = try await DeterministicBaseballHostEditor().editorial(
            for: plan,
            snapshot: snapshot,
            profile: profile
        )

        XCTAssertEqual(query.intent, .favoriteTeam)
        XCTAssertEqual(query.entities.first?.canonicalName, "Colorado Rockies")
        XCTAssertEqual(editorial.reaction.line, "Your favorite team is the Colorado Rockies.")
        XCTAssertEqual(editorial.reaction.kind, .fact)
        XCTAssertFalse(editorial.reaction.groundedFactIDs.isEmpty)
        XCTAssertTrue(snapshot.modules.contains { module in
            if case .team(let team) = module {
                return team.name == "Colorado Rockies"
            }
            return false
        })
    }

    func testFavoritePlayerQuestionUsesProfileWithoutSubstitutingAnotherFixture() async throws {
        let base = MockMichaelProfile.value
        let profile = BaseballFanProfileSnapshot(
            id: "custom-fan",
            name: base.name,
            favoriteTeam: base.favoriteTeam,
            favoritePlayers: ["A Player Without A Fixture"],
            rivalTeams: base.rivalTeams,
            interests: base.interests,
            stadiumVisits: base.stadiumVisits,
            frequentSearchThemes: base.frequentSearchThemes
        )
        let query = try await DeterministicBaseballQueryInterpreter().interpret(
            "Who is my favorite player?",
            profile: profile
        )
        let plan = DefaultBaseballSearchPlanner().plan(for: query)
        let snapshot = try await MockBaseballDataService().fetch(
            plan: plan,
            profile: profile
        )
        let editorial = try await DeterministicBaseballHostEditor().editorial(
            for: plan,
            snapshot: snapshot,
            profile: profile
        )

        XCTAssertEqual(
            editorial.reaction.line,
            "Your favorite player is A Player Without A Fixture."
        )
        XCTAssertFalse(snapshot.modules.contains { module in
            if case .player(let player) = module {
                return player.name == "Hunter Goodman"
            }
            return false
        })
    }

    func testUnknownQuestionBecomesARefinementFailure() async {
        let commish = TestCommishController()
        let environment = BaseballSearchEnvironment(
            dependencies: BaseballSearchDependencies(
                profile: MockMichaelProfile.value,
                queryInterpreter: DeterministicBaseballQueryInterpreter(),
                planner: DefaultBaseballSearchPlanner(),
                dataProvider: MockBaseballDataService(),
                discoveryProvider: MockBaseballDiscoveryService(),
                hostEditor: DeterministicBaseballHostEditor(),
                resultComposer: DefaultBaseballResultComposer(),
                host: LegacyCommishHostAdapter(controller: commish)
            )
        )

        await environment.search("Tell me something")

        guard case .failed(let failure) = environment.state else {
            return XCTFail("Unknown queries must not become host opinions")
        }
        XCTAssertTrue(failure.message.contains("couldn’t identify"))
        XCTAssertTrue(failure.recoverySuggestions.isEmpty)
        XCTAssertEqual(commish.currentAction, .idle)
    }

    func testMikeSchmidtLookupReturnsGroundedPlayerContent() async throws {
        let profile = MockMichaelProfile.value
        let query = try await DeterministicBaseballQueryInterpreter().interpret(
            "mike schmidt",
            profile: profile
        )
        let plan = DefaultBaseballSearchPlanner().plan(for: query)
        let snapshot = try await MockBaseballDataService().fetch(
            plan: plan,
            profile: profile
        )
        let editorial = try await DeterministicBaseballHostEditor().editorial(
            for: plan,
            snapshot: snapshot,
            profile: profile
        )

        XCTAssertEqual(query.intent, .entityLookup)
        XCTAssertEqual(query.entities.first?.canonicalName, "Mike Schmidt")
        XCTAssertTrue(snapshot.modules.contains { module in
            if case .player(let player) = module {
                return player.id == "mike-schmidt"
                    && player.teamName == "Philadelphia Phillies"
            }
            return false
        })
        XCTAssertTrue(editorial.reaction.line.contains("Phillies icon"))
        XCTAssertTrue(editorial.reaction.line.contains("Hall of Fame"))
    }

    func testPlannerProducesVisualModulePlansInsteadOfTextResponses() async throws {
        let query = try await DeterministicBaseballQueryInterpreter().interpret(
            "Aaron Judge",
            profile: MockMichaelProfile.value
        )
        let plan = DefaultBaseballSearchPlanner().plan(for: query)

        XCTAssertEqual(plan.hostBehavior, .explain)
        XCTAssertEqual(plan.requestedModules.first, .hostReaction)
        XCTAssertTrue(plan.requestedModules.contains(.player))
        XCTAssertTrue(plan.requestedModules.contains(.statcast))
        XCTAssertTrue(plan.requestedModules.contains(.whyThisMatters))
        XCTAssertTrue(plan.requestedModules.contains(.relatedSearches))
        XCTAssertFalse(plan.requestedModules.contains(.game))
        XCTAssertFalse(plan.requestedModules.contains(.highlight))
        XCTAssertFalse(plan.requestedModules.contains(.watchNext))
        XCTAssertEqual(Set(plan.requestedModules).count, 5)
    }

    func testJudgeLookupUsesOnlyJudgeRelevantFixturesAndSpecificEditorial() async throws {
        let profile = MockMichaelProfile.value
        let query = try await DeterministicBaseballQueryInterpreter().interpret(
            "aaron judge",
            profile: profile
        )
        let plan = DefaultBaseballSearchPlanner().plan(for: query)
        let snapshot = try await MockBaseballDataService().fetch(
            plan: plan,
            profile: profile
        )
        let editorial = try await DeterministicBaseballHostEditor().editorial(
            for: plan,
            snapshot: snapshot,
            profile: profile
        )

        XCTAssertTrue(snapshot.modules.contains { module in
            if case .player(let player) = module { return player.name == "Aaron Judge" }
            return false
        })
        XCTAssertTrue(snapshot.modules.contains { module in
            if case .statcast(let statcast) = module {
                return statcast.id == MockBaseballFixtures.judgeStatcast.id
            }
            return false
        })
        XCTAssertFalse(snapshot.modules.contains { module in
            if case .game = module { return true }
            if case .highlight = module { return true }
            if case .watchNext = module { return true }
            return false
        })
        XCTAssertTrue(editorial.reaction.line.contains("Aaron Judge"))
        XCTAssertTrue(editorial.reaction.line.contains("Contact quality"))
        XCTAssertFalse(editorial.reaction.line.contains("spotlight"))
        XCTAssertFalse(editorial.reaction.line.contains("deserves your time"))
        XCTAssertTrue(editorial.whyThisMatters.explanation.contains("explicit subject"))
        XCTAssertFalse(editorial.whyThisMatters.explanation.contains("playoff implications"))
    }

    func testOhtaniLookupCannotBorrowJudgeOrRockiesFixtures() async throws {
        let profile = MockMichaelProfile.value
        let query = try await DeterministicBaseballQueryInterpreter().interpret(
            "shohei ohtani",
            profile: profile
        )
        let plan = DefaultBaseballSearchPlanner().plan(for: query)
        let snapshot = try await MockBaseballDataService().fetch(
            plan: plan,
            profile: profile
        )
        let editorial = try await DeterministicBaseballHostEditor().editorial(
            for: plan,
            snapshot: snapshot,
            profile: profile
        )

        XCTAssertTrue(snapshot.modules.contains { module in
            if case .player(let player) = module { return player.name == "Shohei Ohtani" }
            return false
        })
        XCTAssertFalse(snapshot.modules.contains { module in
            if case .statcast = module { return true }
            if case .game = module { return true }
            if case .highlight = module { return true }
            if case .watchNext = module { return true }
            return false
        })
        XCTAssertTrue(editorial.reaction.line.contains("designated hitter"))
        XCTAssertTrue(editorial.reaction.line.contains("current sourcing"))
    }

    func testMockDataIsAlwaysMarkedAsFixtureData() async throws {
        let query = try await DeterministicBaseballQueryInterpreter().interpret(
            "Compare Judge and Ohtani",
            profile: MockMichaelProfile.value
        )
        let plan = DefaultBaseballSearchPlanner().plan(for: query)
        let snapshot = try await MockBaseballDataService().fetch(
            plan: plan,
            profile: MockMichaelProfile.value
        )

        XCTAssertFalse(snapshot.modules.isEmpty)
        XCTAssertFalse(snapshot.supportingFacts.isEmpty)
        XCTAssertTrue(snapshot.supportingFacts.allSatisfy { $0.kind == .fact })
        XCTAssertTrue(snapshot.supportingFacts.allSatisfy(\.provenance.isMock))
        XCTAssertTrue(
            snapshot.supportingFacts.allSatisfy {
                $0.provenance.sourceName.contains("not live MLB data")
            }
        )
    }

    func testDiscoveryExplainsWhyMichaelShouldCare() async throws {
        let cards = try await MockBaseballDiscoveryService().cards(
            for: MockMichaelProfile.value
        )

        XCTAssertGreaterThanOrEqual(cards.count, 5)
        XCTAssertTrue(cards.allSatisfy { !$0.whyItMatters.isEmpty })
        XCTAssertTrue(cards.allSatisfy { !$0.destinationQuery.isEmpty })
        XCTAssertTrue(cards.allSatisfy { !$0.facts.isEmpty })
        XCTAssertTrue(
            cards
                .filter { $0.playerStory == nil }
                .flatMap(\.facts)
                .allSatisfy(\.provenance.isMock)
        )
        XCTAssertEqual(cards.first?.finalScore?.visitorTeam, "Rockies")
        XCTAssertEqual(cards.first?.finalScore?.homeTeam, "Brewers")
        XCTAssertEqual(cards.first?.finalScore?.visitorRuns, 2)
        XCTAssertEqual(cards.first?.finalScore?.homeRuns, 11)
        XCTAssertEqual(cards.dropFirst().first?.id, "discovery-standings")
        XCTAssertEqual(cards.dropFirst().first?.standings?.divisionPosition, 5)
        XCTAssertEqual(cards.dropFirst().first?.standings?.lastTen, "3–7")
        XCTAssertEqual(cards.dropFirst().first?.standings?.streak, "L2")
        XCTAssertEqual(cards.dropFirst().first?.standings?.runDifferential, -110)
        XCTAssertEqual(
            cards.dropFirst().first?.standings?.comparisonRunDifferential,
            -127
        )
        XCTAssertEqual(
            cards.dropFirst().first?.standings?.nextOpponent,
            "San Diego Padres"
        )
        let storyCard = cards.dropFirst(2).first
        XCTAssertEqual(storyCard?.id, "discovery-goodman-story")
        XCTAssertEqual(storyCard?.playerStory?.playerName, "Hunter Goodman")
        XCTAssertEqual(storyCard?.playerStory?.highlights.count, 4)
        XCTAssertEqual(
            storyCard?.playerStory?.sourceURL.absoluteString,
            "https://www.mlb.com/stories/player/696100"
        )
        XCTAssertTrue(
            storyCard?.facts.allSatisfy { !$0.provenance.isMock } == true
        )
    }

    func testDiscoveryCardSelectionDrivesHostChoreography() async {
        let commish = TestCommishController()
        let environment = BaseballSearchEnvironment(
            dependencies: BaseballSearchDependencies(
                profile: MockMichaelProfile.value,
                queryInterpreter: DeterministicBaseballQueryInterpreter(),
                planner: DefaultBaseballSearchPlanner(),
                dataProvider: MockBaseballDataService(),
                discoveryProvider: MockBaseballDiscoveryService(),
                hostEditor: DeterministicBaseballHostEditor(),
                resultComposer: DefaultBaseballResultComposer(),
                host: LegacyCommishHostAdapter(controller: commish)
            )
        )

        await environment.loadDiscovery()

        XCTAssertEqual(
            environment.activeDiscoveryCardID,
            "discovery-rockies-tonight"
        )
        XCTAssertEqual(commish.currentAction, .sadShrug)

        environment.moveDiscoveryCard(by: 1)
        XCTAssertEqual(
            environment.activeDiscoveryCardID,
            "discovery-standings"
        )
        XCTAssertEqual(commish.currentAction, .sadShrug)

        environment.presentDiscoveryCard("discovery-goodman-story")
        XCTAssertEqual(
            environment.activeDiscoveryCardID,
            "discovery-goodman-story"
        )
        XCTAssertEqual(commish.currentAction, .foamFinger)

        environment.moveDiscoveryCard(by: -1)
        XCTAssertEqual(
            environment.activeDiscoveryCardID,
            "discovery-standings"
        )
        XCTAssertEqual(commish.currentAction, .sadShrug)

        environment.moveDiscoveryCard(by: -1)
        XCTAssertEqual(
            environment.activeDiscoveryCardID,
            "discovery-rockies-tonight"
        )
        XCTAssertEqual(commish.currentAction, .sadShrug)
    }

    func testLegacyHostAdapterMapsGenericBehaviorWithoutUIKnowledge() {
        let commish = TestCommishController()
        let host = LegacyCommishHostAdapter(controller: commish)

        host.perform(.celebrate)
        XCTAssertEqual(commish.currentAction, .foamFinger)

        host.perform(.concerned)
        XCTAssertEqual(commish.currentAction, .sadShrug)

        host.perform(.think)
        XCTAssertEqual(commish.currentAction, .idle)

        host.perform(.interrupt)
        XCTAssertEqual(commish.currentAction, .pointRight)
        XCTAssertEqual(host.descriptor.disclosure, "Living Commish is a fictional animated guide.")
    }

    func testEnvironmentUsesInjectedSearchDependencies() async {
        let commish = TestCommishController()
        let injectedQuery = BaseballSearchQuery(
            rawText: "injected",
            intent: .gamesTonight,
            entities: [],
            timeScope: .tonight,
            requiresPersonalHistory: false,
            ambiguity: nil
        )
        let dependencies = BaseballSearchDependencies(
            profile: MockMichaelProfile.value,
            queryInterpreter: StubQueryInterpreter(query: injectedQuery),
            planner: DefaultBaseballSearchPlanner(),
            dataProvider: MockBaseballDataService(),
            discoveryProvider: MockBaseballDiscoveryService(),
            hostEditor: DeterministicBaseballHostEditor(),
            resultComposer: DefaultBaseballResultComposer(),
            host: LegacyCommishHostAdapter(controller: commish)
        )
        let environment = BaseballSearchEnvironment(dependencies: dependencies)

        await environment.loadDiscovery()
        XCTAssertGreaterThanOrEqual(environment.discoveryCards.count, 5)

        await environment.search("this text is intentionally not baseball")
        guard case .presenting(let experience) = environment.state else {
            return XCTFail("Expected an injected search experience, got \(environment.state)")
        }

        XCTAssertEqual(experience.query.intent, .gamesTonight)
        XCTAssertEqual(experience.modules.first?.id, "host:reaction-gamesTonight")
        XCTAssertTrue(experience.modules.contains { module in
            if case .game = module { return true }
            return false
        })
        XCTAssertEqual(commish.currentAction, .pointRight)
    }
}

private struct StubQueryInterpreter: BaseballQueryInterpreting {
    let query: BaseballSearchQuery

    func interpret(
        _ rawText: String,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballSearchQuery {
        query
    }
}

@MainActor
private final class TestCommishController: CommishControlling {
    var isReady = true
    var currentAction: CommishAction = .idle
    let rendererName = "Test renderer"
    var currentFrame: UIImage?
    var rendererView: AnyView?
    var fallbackReason: String?
    private(set) var isApplicationActive = true

    func play(_ action: CommishAction) {
        currentAction = action
    }

    func reset() {
        currentAction = .idle
    }

    func setApplicationActive(_ isActive: Bool) {
        isApplicationActive = isActive
    }
}
