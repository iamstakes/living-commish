import Foundation

enum BaseballClaimKind: String, CaseIterable, Codable, Sendable {
    case fact
    case opinion
    case prediction

    var displayName: String {
        switch self {
        case .fact: "Fact"
        case .opinion: "Host opinion"
        case .prediction: "Prediction"
        }
    }
}

struct BaseballProvenance: Equatable, Codable, Sendable {
    let sourceName: String
    let asOf: Date
    let isMock: Bool

    static func prototypeFixture(asOf: Date) -> BaseballProvenance {
        BaseballProvenance(
            sourceName: "Prototype fixture — not live MLB data",
            asOf: asOf,
            isMock: true
        )
    }
}

struct BaseballFact: Equatable, Identifiable, Codable, Sendable {
    let id: String
    let statement: String
    let kind: BaseballClaimKind
    let provenance: BaseballProvenance
}

struct BaseballPlayerCard: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let teamName: String
    let position: String
    let summary: String
    let facts: [BaseballFact]
    let gallery: [BaseballPlayerGalleryImage]
    let quiz: BaseballDailyDrop?
}

struct BaseballPlayerGalleryImage: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let caption: String
    let imageURL: String
    let sourceName: String
}

enum BaseballPlayerInsightKind: String, Equatable, Sendable {
    case careerStats
    case modernComparison
    case hallOfFameLegacy
}

struct BaseballPlayerInsightCard: Equatable, Identifiable, Sendable {
    let id: String
    let kind: BaseballPlayerInsightKind
    let title: String
    let headline: String
    let summary: String
    let facts: [BaseballFact]
}

struct BaseballTeamCard: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let abbreviation: String
    let summary: String
    let facts: [BaseballFact]
}

enum BaseballGameStatus: String, Equatable, Sendable {
    case scheduled
    case live
    case final
}

struct BaseballGameCard: Equatable, Identifiable, Sendable {
    let id: String
    let awayTeam: String
    let homeTeam: String
    let venue: String
    let startsAt: Date
    let status: BaseballGameStatus
    let statusText: String
    let facts: [BaseballFact]
}

struct BaseballStandingsCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let facts: [BaseballFact]
}

struct BaseballHighlightCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let durationSeconds: Int
    let facts: [BaseballFact]
}

struct BaseballStatcastCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let metricName: String
    let metricValue: String
    let explanation: String
    let facts: [BaseballFact]
}

struct BaseballComparisonCard: Equatable, Identifiable, Sendable {
    let id: String
    let leftName: String
    let rightName: String
    let headline: String
    let facts: [BaseballFact]
}

struct BaseballPersonalMemoryCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let detail: String
    let occurredAt: Date
    let facts: [BaseballFact]
}

struct BaseballWatchNextCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let reason: String
    let query: String
    let facts: [BaseballFact]
}

struct BaseballWhyThisMattersCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let kind: BaseballClaimKind
    let groundedFactIDs: [String]
}

struct BaseballRelatedSearchesCard: Equatable, Identifiable, Sendable {
    let id: String
    let searches: [String]
}

struct BaseballHostReaction: Equatable, Identifiable, Sendable {
    let id: String
    let line: String
    let kind: BaseballClaimKind
    let providerName: String
    let groundedFactIDs: [String]
    let behavior: HostBehavior
}

enum BaseballResultModule: Equatable, Identifiable, Sendable {
    case hostReaction(BaseballHostReaction)
    case player(BaseballPlayerCard)
    case team(BaseballTeamCard)
    case game(BaseballGameCard)
    case standings(BaseballStandingsCard)
    case highlight(BaseballHighlightCard)
    case statcast(BaseballStatcastCard)
    case comparison(BaseballComparisonCard)
    case playerInsight(BaseballPlayerInsightCard)
    case personalMemory(BaseballPersonalMemoryCard)
    case whyThisMatters(BaseballWhyThisMattersCard)
    case relatedSearches(BaseballRelatedSearchesCard)
    case watchNext(BaseballWatchNextCard)

    var id: String {
        switch self {
        case .hostReaction(let value): "host:\(value.id)"
        case .player(let value): "player:\(value.id)"
        case .team(let value): "team:\(value.id)"
        case .game(let value): "game:\(value.id)"
        case .standings(let value): "standings:\(value.id)"
        case .highlight(let value): "highlight:\(value.id)"
        case .statcast(let value): "statcast:\(value.id)"
        case .comparison(let value): "comparison:\(value.id)"
        case .playerInsight(let value): "player-insight:\(value.id)"
        case .personalMemory(let value): "memory:\(value.id)"
        case .whyThisMatters(let value): "why:\(value.id)"
        case .relatedSearches(let value): "related:\(value.id)"
        case .watchNext(let value): "watch:\(value.id)"
        }
    }

    var facts: [BaseballFact] {
        switch self {
        case .player(let value): value.facts
        case .team(let value): value.facts
        case .game(let value): value.facts
        case .standings(let value): value.facts
        case .highlight(let value): value.facts
        case .statcast(let value): value.facts
        case .comparison(let value): value.facts
        case .playerInsight(let value): value.facts
        case .personalMemory(let value): value.facts
        case .watchNext(let value): value.facts
        case .hostReaction, .whyThisMatters, .relatedSearches: []
        }
    }
}
