import Foundation
import FoundationModels

protocol CollegeFootballQueryInterpreting: Sendable {
    func interpret(
        _ rawText: String,
        profile: CollegeFootballFanProfileSnapshot
    ) async throws -> CollegeFootballSearchQuery
}

protocol CollegeFootballSearchPlanning: Sendable {
    func plan(for query: CollegeFootballSearchQuery) -> CollegeFootballSearchPlan
}

protocol CollegeFootballDataProviding: Sendable {
    func fetch(
        plan: CollegeFootballSearchPlan,
        profile: CollegeFootballFanProfileSnapshot
    ) async throws -> CollegeFootballDataSnapshot
}

protocol CollegeFootballDiscoveryProviding: Sendable {
    func cards(
        for profile: CollegeFootballFanProfileSnapshot
    ) async throws -> [CollegeFootballDiscoveryCard]
}

protocol CollegeFootballResultComposing: Sendable {
    func compose(
        plan: CollegeFootballSearchPlan,
        snapshot: CollegeFootballDataSnapshot,
        editorial: CollegeFootballHostEditorial
    ) -> CollegeFootballSearchExperience
}

enum CollegeFootballSearchArchitectureError: LocalizedError, Equatable {
    case emptyQuery
    case needsRefinement(String)
    case noFixture(String)

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            "Enter a player, program, game, or college football question."
        case .needsRefinement(let guidance):
            guidance
        case .noFixture(let query):
            "The prototype has no structured fixture for “\(query)” yet."
        }
    }
}

enum AppleCollegeFootballSearchIntent: String, Codable, CaseIterable, Sendable {
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

enum AppleCollegeFootballEntityKind: String, Codable, CaseIterable, Sendable {
    case player
    case team
}

enum AppleCollegeFootballTimeScope: String, Codable, CaseIterable, Sendable {
    case today
    case tonight
    case yesterday
    case upcoming
    case allTime
    case unspecified
}

struct AppleCollegeFootballEntity: Codable, Equatable, Sendable {
    var canonicalName: String
    var kind: AppleCollegeFootballEntityKind
}

struct AppleCollegeFootballInterpretation: Codable, Equatable, Sendable {
    var intent: AppleCollegeFootballSearchIntent
    var entities: [AppleCollegeFootballEntity]
    var timeScope: AppleCollegeFootballTimeScope
    var requiresPersonalHistory: Bool
}

enum AppleCollegeFootballInterpretationError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Apple Intelligence returned an invalid college football search interpretation."
    }
}

struct AppleFoundationModelsCollegeFootballQueryInterpreter: CollegeFootballQueryInterpreting {
    private let model = SystemLanguageModel.default

    var isAvailable: Bool { model.isAvailable }

    func interpret(
        _ rawText: String,
        profile: CollegeFootballFanProfileSnapshot
    ) async throws -> CollegeFootballSearchQuery {
        let cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw CollegeFootballSearchArchitectureError.emptyQuery
        }
        guard model.isAvailable else {
            throw CollegeFootballSearchArchitectureError.needsRefinement(
                "Apple Intelligence is unavailable for this search."
            )
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You classify college football searches for a native app.
            Return structured intent, named entities, time scope, and whether the request needs the fan's personal history.
            Extract names; do not answer the question.
            Never invent a player, team, statistic, result, or schedule fact.
            A bare person's name such as "Travis Hunter" is an entity lookup.
            A bare program name is a team lookup.
            Questions about "my favorite team" or "my favorite player" use the corresponding favorite intent.
            Use unknown only when the text cannot reasonably be interpreted as a college football search.
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
            {"intent":"entityLookup","entities":[{"canonicalName":"Travis Hunter","kind":"player"}],"timeScope":"unspecified","requiresPersonalHistory":false}
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
    ) throws -> AppleCollegeFootballInterpretation {
        guard let start = rawResponse.firstIndex(of: "{"),
              let end = rawResponse.lastIndex(of: "}"),
              start <= end else {
            throw AppleCollegeFootballInterpretationError.invalidResponse
        }

        let json = String(rawResponse[start...end])
        guard let data = json.data(using: .utf8),
              let interpretation = try? JSONDecoder().decode(
                AppleCollegeFootballInterpretation.self,
                from: data
              ) else {
            throw AppleCollegeFootballInterpretationError.invalidResponse
        }
        return interpretation
    }

    static func makeQuery(
        rawText: String,
        interpretation: AppleCollegeFootballInterpretation,
        profile: CollegeFootballFanProfileSnapshot
    ) -> CollegeFootballSearchQuery {
        let intent = CollegeFootballSearchIntent(rawValue: interpretation.intent.rawValue)
            ?? .unknown
        var entities = interpretation.entities.map { entity in
            canonicalEntity(
                named: entity.canonicalName,
                kind: CollegeFootballEntityKind(rawValue: entity.kind.rawValue) ?? .player
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

        let normalizedIntent: CollegeFootballSearchIntent
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
            ambiguity = "I couldn’t identify a grounded college football result for “\(rawText)”."
        } else if normalizedIntent == .playerComparison,
                  entities.filter({ $0.kind == .player }).count < 2 {
            ambiguity = "Choose two players to compare."
        } else {
            ambiguity = nil
        }

        return CollegeFootballSearchQuery(
            rawText: rawText,
            intent: normalizedIntent,
            entities: deduplicated(entities),
            timeScope: CollegeFootballTimeScope(
                rawValue: interpretation.timeScope.rawValue
            ) ?? .unspecified,
            requiresPersonalHistory: interpretation.requiresPersonalHistory
                || normalizedIntent == .personalAttendanceHistory,
            ambiguity: ambiguity
        )
    }

    private static func canonicalEntity(
        named rawName: String,
        kind: CollegeFootballEntityKind
    ) -> CollegeFootballEntityReference {
        let cleaned = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lookup = cleaned.lowercased()
        let canonicalName: String

        switch (kind, lookup) {
        case (.player, "hunter"), (.player, "travis hunter"):
            canonicalName = "Travis Hunter"
        case (.player, "shedeur"), (.player, "shedeur sanders"):
            canonicalName = "Shedeur Sanders"
        case (.player, "jeanty"), (.player, "ashton jeanty"):
            canonicalName = "Ashton Jeanty"
        case (.player, "woodson"), (.player, "charles woodson"):
            canonicalName = "Charles Woodson"
        case (.team, "buffs"),
             (.team, "buffaloes"),
             (.team, "colorado buffs"),
             (.team, "colorado buffaloes"):
            canonicalName = "Colorado Buffaloes"
        case (.team, "nebraska"),
             (.team, "cornhuskers"),
             (.team, "nebraska cornhuskers"):
            canonicalName = "Nebraska Cornhuskers"
        default:
            canonicalName = cleaned
        }

        return CollegeFootballEntityReference(
            id: "\(kind.rawValue)-\(slug(canonicalName))",
            kind: kind,
            canonicalName: canonicalName
        )
    }

    private static func deduplicated(
        _ entities: [CollegeFootballEntityReference]
    ) -> [CollegeFootballEntityReference] {
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

struct AdaptiveCollegeFootballQueryInterpreter: CollegeFootballQueryInterpreting {
    private let apple = AppleFoundationModelsCollegeFootballQueryInterpreter()
    private let deterministic = DeterministicCollegeFootballQueryInterpreter()
    private let forceDeterministicFallback: Bool

    init(forceDeterministicFallback: Bool = false) {
        self.forceDeterministicFallback = forceDeterministicFallback
    }

    func interpret(
        _ rawText: String,
        profile: CollegeFootballFanProfileSnapshot
    ) async throws -> CollegeFootballSearchQuery {
        if apple.isAvailable && !forceDeterministicFallback {
            do {
                let appleQuery = try await apple.interpret(
                    rawText,
                    profile: profile
                )
                if appleQuery.intent != .unknown {
#if DEBUG
                    print("CollegeFootball search interpreted by Apple Foundation Models.")
#endif
                    return appleQuery
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
#if DEBUG
                print(
                    "CollegeFootball Apple interpretation failed; using deterministic fallback: \(error.localizedDescription)"
                )
#endif
            }
        }

        return try await deterministic.interpret(rawText, profile: profile)
    }
}

struct DeterministicCollegeFootballQueryInterpreter: CollegeFootballQueryInterpreting {
    func interpret(
        _ rawText: String,
        profile: CollegeFootballFanProfileSnapshot
    ) async throws -> CollegeFootballSearchQuery {
        let cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw CollegeFootballSearchArchitectureError.emptyQuery }

        let normalized = cleaned
            .replacingOccurrences(of: "’", with: "'")
            .lowercased()
        let entities = recognizedEntities(in: normalized, profile: profile)

        let intent: CollegeFootballSearchIntent
        if asksForFavoriteTeam(normalized) {
            intent = .favoriteTeam
        } else if asksForFavoritePlayer(normalized) {
            intent = .favoritePlayer
        } else if containsAny(normalized, ["compare ", " versus ", " vs. ", " vs "]) {
            intent = .playerComparison
        } else if containsAny(normalized, ["when was my last", "my last game", "last game i attended"]) {
            intent = .personalAttendanceHistory
        } else if containsAny(normalized, ["cfp", "playoff odds", "playoff path", "playoff race", "affect the standings", "conference race"]) {
            intent = .standingsImpact
        } else if containsAny(normalized, ["what did i miss", "missed yesterday", "recap yesterday"]) {
            intent = .missedGamesRecap
        } else if normalized.contains("why"),
                  containsAny(normalized, ["isn't", "is not", "not pitching", "not playing", "out of the lineup"]) {
            intent = .availabilityExplanation
        } else if containsAny(normalized, ["games tonight", "game tonight", "who plays tonight", "games this weekend", "games saturday", "who plays saturday"]) {
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

        let timeScope: CollegeFootballTimeScope
        if normalized.contains("tonight") {
            timeScope = .tonight
        } else if normalized.contains("yesterday") {
            timeScope = .yesterday
        } else if normalized.contains("today") {
            timeScope = .today
        } else if normalized.contains("next")
                    || normalized.contains("upcoming")
                    || normalized.contains("weekend")
                    || normalized.contains("saturday") {
            timeScope = .upcoming
        } else if intent == .personalAttendanceHistory {
            timeScope = .allTime
        } else {
            timeScope = .unspecified
        }

        let ambiguity: String?
        if intent == .unknown {
            ambiguity = "I couldn’t identify a grounded college football result for “\(cleaned)”."
        } else if intent == .playerComparison, entities.filter({ $0.kind == .player }).count < 2 {
            ambiguity = "Choose two players to compare."
        } else {
            ambiguity = nil
        }

        return CollegeFootballSearchQuery(
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
        profile: CollegeFootballFanProfileSnapshot
    ) -> [CollegeFootballEntityReference] {
        var entities: [CollegeFootballEntityReference] = []

        func append(_ entity: CollegeFootballEntityReference) {
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
        if containsAny(text, ["travis hunter", "hunter"]) {
            append(.init(id: "player-travis-hunter", kind: .player, canonicalName: "Travis Hunter"))
        }
        if containsAny(text, ["shedeur sanders", "shedeur"]) {
            append(.init(id: "player-shedeur-sanders", kind: .player, canonicalName: "Shedeur Sanders"))
        }
        if containsAny(text, ["ashton jeanty", "jeanty"]) {
            append(.init(id: "player-ashton-jeanty", kind: .player, canonicalName: "Ashton Jeanty"))
        }
        if containsAny(text, ["charles woodson", "woodson"]) {
            append(.init(id: "player-charles-woodson", kind: .player, canonicalName: "Charles Woodson"))
        }
        if containsAny(text, ["colorado buffaloes", "colorado buffs", "buffaloes", "buffs", "colorado"]) {
            append(.init(id: "team-colorado-buffaloes", kind: .team, canonicalName: "Colorado Buffaloes"))
        }
        if containsAny(text, ["nebraska cornhuskers", "cornhuskers", "nebraska"]) {
            append(.init(id: "team-nebraska-cornhuskers", kind: .team, canonicalName: "Nebraska Cornhuskers"))
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

struct DefaultCollegeFootballSearchPlanner: CollegeFootballSearchPlanning {
    func plan(for query: CollegeFootballSearchQuery) -> CollegeFootballSearchPlan {
        let modules: [CollegeFootballResultModuleKind]
        let behavior: HostBehavior

        switch query.intent {
        case .favoriteTeam:
            modules = [.hostReaction, .team, .whyThisMatters, .relatedSearches]
            behavior = .greet
        case .favoritePlayer:
            modules = [.hostReaction, .player, .whyThisMatters, .relatedSearches]
            behavior = .greet
        case .entityLookup:
            if query.entities.contains(where: { $0.id == "player-travis-hunter" }) {
                modules = [
                    .hostReaction, .player, .performance, .playerInsights,
                    .whyThisMatters,
                ]
            } else if query.entities.contains(where: { $0.id == "player-shedeur-sanders" }) {
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
                .hostReaction, .player, .historicalComparison, .performance,
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

        return CollegeFootballSearchPlan(
            query: query,
            requestedModules: modules,
            hostBehavior: behavior
        )
    }
}

struct DefaultCollegeFootballResultComposer: CollegeFootballResultComposing {
    func compose(
        plan: CollegeFootballSearchPlan,
        snapshot: CollegeFootballDataSnapshot,
        editorial: CollegeFootballHostEditorial
    ) -> CollegeFootballSearchExperience {
        var modules: [CollegeFootballResultModule] = [.hostReaction(editorial.reaction)]
        modules.append(contentsOf: snapshot.modules)
        if plan.requestedModules.contains(.whyThisMatters) {
            modules.append(.whyThisMatters(editorial.whyThisMatters))
        }

        var seenIDs: Set<String> = []
        let deduplicated = modules.filter { seenIDs.insert($0.id).inserted }
        return CollegeFootballSearchExperience(
            query: plan.query,
            modules: deduplicated,
            generatedAt: .now
        )
    }
}
