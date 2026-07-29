import Foundation
import FoundationModels

protocol BaseballQueryInterpreting: Sendable {
    func interpret(
        _ rawText: String,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballSearchQuery
}

protocol BaseballSearchPlanning: Sendable {
    func plan(for query: BaseballSearchQuery) -> BaseballSearchPlan
}

protocol BaseballDataProviding: Sendable {
    func fetch(
        plan: BaseballSearchPlan,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballDataSnapshot
}

protocol BaseballDiscoveryProviding: Sendable {
    func cards(
        for profile: BaseballFanProfileSnapshot
    ) async throws -> [BaseballDiscoveryCard]
}

protocol BaseballResultComposing: Sendable {
    func compose(
        plan: BaseballSearchPlan,
        snapshot: BaseballDataSnapshot,
        editorial: BaseballHostEditorial
    ) -> BaseballSearchExperience
}

enum BaseballSearchArchitectureError: LocalizedError, Equatable {
    case emptyQuery
    case needsRefinement(String)
    case noFixture(String)

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            "Enter a player, team, game, or baseball question."
        case .needsRefinement(let guidance):
            guidance
        case .noFixture(let query):
            "The prototype has no structured fixture for “\(query)” yet."
        }
    }
}

enum AppleBaseballSearchIntent: String, Codable, CaseIterable, Sendable {
    case favoriteTeam
    case favoritePlayer
    case entityLookup
    case teamLookup
    case gamesTonight
    case playerRecommendation
    case playerComparison
    case availabilityExplanation
    case missedGamesRecap
    case standingsImpact
    case personalAttendanceHistory
    case watchNext
    case unknown
}

enum AppleBaseballEntityKind: String, Codable, CaseIterable, Sendable {
    case player
    case team
}

enum AppleBaseballTimeScope: String, Codable, CaseIterable, Sendable {
    case today
    case tonight
    case yesterday
    case upcoming
    case allTime
    case unspecified
}

struct AppleBaseballEntity: Codable, Equatable, Sendable {
    var canonicalName: String
    var kind: AppleBaseballEntityKind
}

struct AppleBaseballInterpretation: Codable, Equatable, Sendable {
    var intent: AppleBaseballSearchIntent
    var entities: [AppleBaseballEntity]
    var timeScope: AppleBaseballTimeScope
    var requiresPersonalHistory: Bool
}

enum AppleBaseballInterpretationError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Apple Intelligence returned an invalid baseball search interpretation."
    }
}

struct AppleFoundationModelsBaseballQueryInterpreter: BaseballQueryInterpreting {
    private let model = SystemLanguageModel.default

    var isAvailable: Bool { model.isAvailable }

    func interpret(
        _ rawText: String,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballSearchQuery {
        let cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw BaseballSearchArchitectureError.emptyQuery
        }
        guard model.isAvailable else {
            throw BaseballSearchArchitectureError.needsRefinement(
                "Apple Intelligence is unavailable for this search."
            )
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You classify baseball searches for a native app.
            Return structured intent, named entities, time scope, and whether the request needs the fan's personal history.
            Extract names; do not answer the question.
            Never invent a player, team, statistic, result, or schedule fact.
            A bare person's name such as "Mike Schmidt" is an entity lookup.
            A bare club name is a team lookup.
            Questions about "my favorite team" or "my favorite player" use the corresponding favorite intent.
            Use unknown only when the text cannot reasonably be interpreted as a baseball search.
            Allowed intent values: favoriteTeam, favoritePlayer, entityLookup, teamLookup, gamesTonight, playerRecommendation, playerComparison, availabilityExplanation, missedGamesRecap, standingsImpact, personalAttendanceHistory, watchNext, unknown.
            Allowed entity kind values: player, team.
            Allowed timeScope values: today, tonight, yesterday, upcoming, allTime, unspecified.
            """
        )
        let response = try await session.respond(
            to: """
            Fan query: \(cleaned)
            Fan profile name: \(profile.name)
            Favorite team: \(profile.favoriteTeam)
            Favorite players: \(profile.favoritePlayers.joined(separator: ", "))
            Rival teams: \(profile.rivalTeams.joined(separator: ", "))

            Return exactly one JSON object and no markdown:
            {"intent":"entityLookup","entities":[{"canonicalName":"Mike Schmidt","kind":"player"}],"timeScope":"unspecified","requiresPersonalHistory":false}
            """,
            options: GenerationOptions(
                sampling: .greedy,
                temperature: 0.1,
                maximumResponseTokens: 220
            )
        )
        let interpretation = try Self.decodeInterpretation(response.content)

        return Self.makeQuery(
            rawText: cleaned,
            interpretation: interpretation,
            profile: profile
        )
    }

    static func decodeInterpretation(
        _ rawResponse: String
    ) throws -> AppleBaseballInterpretation {
        guard let start = rawResponse.firstIndex(of: "{"),
              let end = rawResponse.lastIndex(of: "}"),
              start <= end else {
            throw AppleBaseballInterpretationError.invalidResponse
        }

        let json = String(rawResponse[start...end])
        guard let data = json.data(using: .utf8),
              let interpretation = try? JSONDecoder().decode(
                AppleBaseballInterpretation.self,
                from: data
              ) else {
            throw AppleBaseballInterpretationError.invalidResponse
        }
        return interpretation
    }

    static func makeQuery(
        rawText: String,
        interpretation: AppleBaseballInterpretation,
        profile: BaseballFanProfileSnapshot
    ) -> BaseballSearchQuery {
        let intent = BaseballSearchIntent(rawValue: interpretation.intent.rawValue)
            ?? .unknown
        var entities = interpretation.entities.map { entity in
            canonicalEntity(
                named: entity.canonicalName,
                kind: BaseballEntityKind(rawValue: entity.kind.rawValue) ?? .player
            )
        }

        if intent == .favoriteTeam {
            entities = [
                canonicalEntity(named: profile.favoriteTeam, kind: .team)
            ]
        } else if intent == .favoritePlayer,
                  let favoritePlayer = profile.favoritePlayers.first {
            entities = [
                canonicalEntity(named: favoritePlayer, kind: .player)
            ]
        }

        let normalizedIntent: BaseballSearchIntent
        if entities.first?.kind == .player,
           intent == .unknown || intent == .teamLookup {
            normalizedIntent = .entityLookup
        } else if entities.first?.kind == .team,
                  intent == .unknown || intent == .entityLookup {
            normalizedIntent = .teamLookup
        } else {
            normalizedIntent = intent
        }

        let ambiguity: String?
        if normalizedIntent == .unknown {
            ambiguity = "I couldn’t identify a grounded baseball result for “\(rawText)”."
        } else if normalizedIntent == .playerComparison,
                  entities.filter({ $0.kind == .player }).count < 2 {
            ambiguity = "Choose two players to compare."
        } else {
            ambiguity = nil
        }

        return BaseballSearchQuery(
            rawText: rawText,
            intent: normalizedIntent,
            entities: deduplicated(entities),
            timeScope: BaseballTimeScope(
                rawValue: interpretation.timeScope.rawValue
            ) ?? .unspecified,
            requiresPersonalHistory: interpretation.requiresPersonalHistory
                || normalizedIntent == .personalAttendanceHistory,
            ambiguity: ambiguity
        )
    }

    private static func canonicalEntity(
        named rawName: String,
        kind: BaseballEntityKind
    ) -> BaseballEntityReference {
        let cleaned = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lookup = cleaned.lowercased()
        let canonicalName: String

        switch (kind, lookup) {
        case (.player, "judge"), (.player, "aaron judge"):
            canonicalName = "Aaron Judge"
        case (.player, "ohtani"), (.player, "shohei ohtani"):
            canonicalName = "Shohei Ohtani"
        case (.player, "goodman"), (.player, "hunter goodman"):
            canonicalName = "Hunter Goodman"
        case (.player, "schmidt"),
             (.player, "michael jack schmidt"),
             (.player, "mike schmidt"):
            canonicalName = "Mike Schmidt"
        case (.team, "rockies"), (.team, "colorado rockies"):
            canonicalName = "Colorado Rockies"
        case (.team, "dodgers"),
             (.team, "la dodgers"),
             (.team, "los angeles dodgers"):
            canonicalName = "Los Angeles Dodgers"
        default:
            canonicalName = cleaned
        }

        return BaseballEntityReference(
            id: "\(kind.rawValue)-\(slug(canonicalName))",
            kind: kind,
            canonicalName: canonicalName
        )
    }

    private static func deduplicated(
        _ entities: [BaseballEntityReference]
    ) -> [BaseballEntityReference] {
        var seen: Set<String> = []
        return entities.filter { seen.insert($0.id).inserted }
    }

    private static func slug(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

struct AdaptiveBaseballQueryInterpreter: BaseballQueryInterpreting {
    private let apple = AppleFoundationModelsBaseballQueryInterpreter()
    private let deterministic = DeterministicBaseballQueryInterpreter()
    private let forceDeterministicFallback: Bool

    init(forceDeterministicFallback: Bool = false) {
        self.forceDeterministicFallback = forceDeterministicFallback
    }

    func interpret(
        _ rawText: String,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballSearchQuery {
        if apple.isAvailable && !forceDeterministicFallback {
            do {
                let appleQuery = try await apple.interpret(
                    rawText,
                    profile: profile
                )
                if appleQuery.intent != .unknown {
#if DEBUG
                    print("Baseball search interpreted by Apple Foundation Models.")
#endif
                    return appleQuery
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
#if DEBUG
                print(
                    "Baseball Apple interpretation failed; using deterministic fallback: \(error.localizedDescription)"
                )
#endif
            }
        }

        return try await deterministic.interpret(rawText, profile: profile)
    }
}

struct DeterministicBaseballQueryInterpreter: BaseballQueryInterpreting {
    func interpret(
        _ rawText: String,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballSearchQuery {
        let cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw BaseballSearchArchitectureError.emptyQuery }

        let normalized = cleaned
            .replacingOccurrences(of: "’", with: "'")
            .lowercased()
        let entities = recognizedEntities(in: normalized, profile: profile)

        let intent: BaseballSearchIntent
        if asksForFavoriteTeam(normalized) {
            intent = .favoriteTeam
        } else if asksForFavoritePlayer(normalized) {
            intent = .favoritePlayer
        } else if containsAny(normalized, ["compare ", " versus ", " vs. ", " vs "]) {
            intent = .playerComparison
        } else if containsAny(normalized, ["when was my last", "my last game", "last game i attended"]) {
            intent = .personalAttendanceHistory
        } else if containsAny(normalized, ["wild card", "playoff odds", "playoff race", "affect the standings"]) {
            intent = .standingsImpact
        } else if containsAny(normalized, ["what did i miss", "missed yesterday", "recap yesterday"]) {
            intent = .missedGamesRecap
        } else if normalized.contains("why"),
                  containsAny(normalized, ["isn't", "is not", "not pitching", "not playing", "out of the lineup"]) {
            intent = .availabilityExplanation
        } else if containsAny(normalized, ["games tonight", "game tonight", "who plays tonight"]) {
            intent = .gamesTonight
        } else if containsAny(normalized, ["watch next", "what should i watch next"]) {
            intent = .watchNext
        } else if containsAny(normalized, ["who should i watch", "player to watch", "recommend a player"]) {
            intent = .playerRecommendation
        } else if entities.first?.kind == .player {
            intent = .entityLookup
        } else if entities.first?.kind == .team {
            intent = .teamLookup
        } else {
            intent = .unknown
        }

        let timeScope: BaseballTimeScope
        if normalized.contains("tonight") {
            timeScope = .tonight
        } else if normalized.contains("yesterday") {
            timeScope = .yesterday
        } else if normalized.contains("today") {
            timeScope = .today
        } else if normalized.contains("next") || normalized.contains("upcoming") {
            timeScope = .upcoming
        } else if intent == .personalAttendanceHistory {
            timeScope = .allTime
        } else {
            timeScope = .unspecified
        }

        let ambiguity: String?
        if intent == .unknown {
            ambiguity = "I couldn’t identify a grounded baseball result for “\(cleaned)”."
        } else if intent == .playerComparison, entities.filter({ $0.kind == .player }).count < 2 {
            ambiguity = "Choose two players to compare."
        } else {
            ambiguity = nil
        }

        return BaseballSearchQuery(
            rawText: cleaned,
            intent: intent,
            entities: entities,
            timeScope: timeScope,
            requiresPersonalHistory: intent == .personalAttendanceHistory,
            ambiguity: ambiguity
        )
    }

    private func recognizedEntities(
        in text: String,
        profile: BaseballFanProfileSnapshot
    ) -> [BaseballEntityReference] {
        var entities: [BaseballEntityReference] = []

        func append(_ entity: BaseballEntityReference) {
            guard !entities.contains(where: { $0.id == entity.id }) else { return }
            entities.append(entity)
        }

        if asksForFavoriteTeam(text) {
            append(
                .init(
                    id: "team-\(slug(profile.favoriteTeam))",
                    kind: .team,
                    canonicalName: profile.favoriteTeam
                )
            )
        }
        if asksForFavoritePlayer(text), let favoritePlayer = profile.favoritePlayers.first {
            append(
                .init(
                    id: "player-\(slug(favoritePlayer))",
                    kind: .player,
                    canonicalName: favoritePlayer
                )
            )
        }
        if containsAny(text, ["aaron judge", "judge"]) {
            append(.init(id: "player-aaron-judge", kind: .player, canonicalName: "Aaron Judge"))
        }
        if containsAny(text, ["shohei ohtani", "ohtani"]) {
            append(.init(id: "player-shohei-ohtani", kind: .player, canonicalName: "Shohei Ohtani"))
        }
        if containsAny(text, ["hunter goodman", "goodman"]) {
            append(.init(id: "player-hunter-goodman", kind: .player, canonicalName: "Hunter Goodman"))
        }
        if containsAny(text, ["mike schmidt", "michael jack schmidt", "schmidt"]) {
            append(.init(id: "player-mike-schmidt", kind: .player, canonicalName: "Mike Schmidt"))
        }
        if containsAny(text, ["colorado rockies", "rockies"]) {
            append(.init(id: "team-colorado-rockies", kind: .team, canonicalName: "Colorado Rockies"))
        }
        if containsAny(text, ["los angeles dodgers", "la dodgers", "dodgers"]) {
            append(.init(id: "team-los-angeles-dodgers", kind: .team, canonicalName: "Los Angeles Dodgers"))
        }
        if text.localizedCaseInsensitiveContains(profile.favoriteTeam) {
            append(
                .init(
                    id: "team-\(slug(profile.favoriteTeam))",
                    kind: .team,
                    canonicalName: profile.favoriteTeam
                )
            )
        }
        return entities
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains(where: text.contains)
    }

    private func asksForFavoriteTeam(_ text: String) -> Bool {
        containsAny(
            text,
            [
                "my favorite team",
                "my favourite team",
                "team do i root for",
                "team am i a fan of",
                "which team do i support",
            ]
        )
    }

    private func asksForFavoritePlayer(_ text: String) -> Bool {
        containsAny(
            text,
            [
                "my favorite player",
                "my favourite player",
                "player do i follow",
                "player am i a fan of",
            ]
        )
    }

    private func slug(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: " ", with: "-")
    }
}

struct DefaultBaseballSearchPlanner: BaseballSearchPlanning {
    func plan(for query: BaseballSearchQuery) -> BaseballSearchPlan {
        let modules: [BaseballResultModuleKind]
        let behavior: HostBehavior

        switch query.intent {
        case .favoriteTeam:
            modules = [.hostReaction, .team, .whyThisMatters, .relatedSearches]
            behavior = .greet
        case .favoritePlayer:
            modules = [.hostReaction, .player, .whyThisMatters, .relatedSearches]
            behavior = .greet
        case .entityLookup:
            if query.entities.contains(where: { $0.id == "player-aaron-judge" }) {
                modules = [
                    .hostReaction, .player, .statcast,
                    .whyThisMatters, .relatedSearches,
                ]
            } else if query.entities.contains(where: { $0.id == "player-hunter-goodman" }) {
                modules = [
                    .hostReaction, .player, .game, .highlight,
                    .whyThisMatters, .relatedSearches, .watchNext,
                ]
            } else {
                modules = [
                    .hostReaction, .player,
                    .whyThisMatters, .relatedSearches,
                ]
            }
            behavior = .explain
        case .teamLookup:
            modules = [
                .hostReaction, .team, .game, .standings,
                .whyThisMatters, .relatedSearches,
            ]
            behavior = .greet
        case .gamesTonight:
            modules = [.hostReaction, .schedule, .whyThisMatters, .watchNext]
            behavior = .interrupt
        case .playerRecommendation:
            modules = [
                .hostReaction, .player, .game, .highlight,
                .whyThisMatters, .watchNext,
            ]
            behavior = .celebrate
        case .playerComparison:
            modules = [
                .hostReaction, .player, .historicalComparison, .statcast,
                .whyThisMatters, .relatedSearches,
            ]
            behavior = .explain
        case .availabilityExplanation:
            modules = [.hostReaction, .player, .whyThisMatters, .relatedSearches]
            behavior = .concerned
        case .missedGamesRecap:
            modules = [
                .hostReaction, .highlight, .game,
                .whyThisMatters, .watchNext,
            ]
            behavior = .greet
        case .standingsImpact:
            modules = [
                .hostReaction, .standings, .game,
                .whyThisMatters, .relatedSearches,
            ]
            behavior = .explain
        case .personalAttendanceHistory:
            modules = [
                .hostReaction, .personalMemory, .highlight,
                .whyThisMatters, .relatedSearches,
            ]
            behavior = .greet
        case .watchNext:
            modules = [.hostReaction, .watchNext, .highlight, .whyThisMatters]
            behavior = .celebrate
        case .unknown:
            modules = [.hostReaction, .relatedSearches]
            behavior = .think
        }

        return BaseballSearchPlan(
            query: query,
            requestedModules: modules,
            hostBehavior: behavior
        )
    }
}

struct DefaultBaseballResultComposer: BaseballResultComposing {
    func compose(
        plan: BaseballSearchPlan,
        snapshot: BaseballDataSnapshot,
        editorial: BaseballHostEditorial
    ) -> BaseballSearchExperience {
        var modules: [BaseballResultModule] = [.hostReaction(editorial.reaction)]
        modules.append(contentsOf: snapshot.modules)
        if plan.requestedModules.contains(.whyThisMatters) {
            modules.append(.whyThisMatters(editorial.whyThisMatters))
        }

        var seenIDs: Set<String> = []
        let deduplicated = modules.filter { seenIDs.insert($0.id).inserted }
        return BaseballSearchExperience(
            query: plan.query,
            modules: deduplicated,
            generatedAt: .now
        )
    }
}
