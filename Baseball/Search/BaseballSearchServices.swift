import Foundation

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
            ambiguity = "Try a player, team, tonight’s games, a comparison, or a playoff question."
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
