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
        XCTAssertTrue(failure.message.contains("Try a player"))
        XCTAssertEqual(commish.currentAction, .idle)
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
        XCTAssertTrue(plan.requestedModules.contains(.highlight))
        XCTAssertTrue(plan.requestedModules.contains(.statcast))
        XCTAssertTrue(plan.requestedModules.contains(.whyThisMatters))
        XCTAssertTrue(plan.requestedModules.contains(.watchNext))
        XCTAssertGreaterThanOrEqual(Set(plan.requestedModules).count, 6)
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
        XCTAssertTrue(cards.flatMap(\.facts).allSatisfy(\.provenance.isMock))
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
