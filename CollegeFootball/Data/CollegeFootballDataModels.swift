import Foundation

enum CollegeFootballClaimKind: String, CaseIterable, Codable, Sendable {
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

struct CollegeFootballProvenance: Equatable, Codable, Sendable {
    let sourceName: String
    let asOf: Date
    let isMock: Bool

    static func prototypeFixture(asOf: Date) -> CollegeFootballProvenance {
        CollegeFootballProvenance(
            sourceName: "Prototype fixture — not live FBS data",
            asOf: asOf,
            isMock: true
        )
    }
}

struct CollegeFootballFact: Equatable, Identifiable, Codable, Sendable {
    let id: String
    let statement: String
    let kind: CollegeFootballClaimKind
    let provenance: CollegeFootballProvenance
}

struct CollegeFootballPlayerCard: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let teamName: String
    let position: String
    let summary: String
    let facts: [CollegeFootballFact]
    let gallery: [CollegeFootballPlayerGalleryImage]
    let quiz: CollegeFootballDailyDrop?
}

struct CollegeFootballPlayerGalleryImage: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let caption: String
    let imageURL: String
    let sourceName: String
}

enum CollegeFootballPlayerInsightKind: String, Equatable, Sendable {
    case careerStats
    case modernComparison
    case hallOfFameLegacy
}

struct CollegeFootballPlayerInsightCard: Equatable, Identifiable, Sendable {
    let id: String
    let kind: CollegeFootballPlayerInsightKind
    let title: String
    let headline: String
    let summary: String
    let facts: [CollegeFootballFact]
}

struct CollegeFootballTeamCard: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let abbreviation: String
    let summary: String
    let facts: [CollegeFootballFact]
}

enum CollegeFootballGameStatus: String, Equatable, Sendable {
    case scheduled
    case live
    case final
}

struct CollegeFootballGameCard: Equatable, Identifiable, Sendable {
    let id: String
    let awayTeam: String
    let homeTeam: String
    let venue: String
    let startsAt: Date
    let status: CollegeFootballGameStatus
    let statusText: String
    let facts: [CollegeFootballFact]
}

struct CollegeFootballStandingsCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let facts: [CollegeFootballFact]
}

struct CollegeFootballHighlightCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let durationSeconds: Int
    let facts: [CollegeFootballFact]
}

struct CollegeFootballPerformanceCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let metricName: String
    let metricValue: String
    let explanation: String
    let facts: [CollegeFootballFact]
}

struct CollegeFootballComparisonCard: Equatable, Identifiable, Sendable {
    let id: String
    let leftName: String
    let rightName: String
    let headline: String
    let facts: [CollegeFootballFact]
}

struct CollegeFootballPersonalMemoryCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let detail: String
    let occurredAt: Date
    let facts: [CollegeFootballFact]
}

struct CollegeFootballWatchNextCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let reason: String
    let query: String
    let facts: [CollegeFootballFact]
}

struct CollegeFootballWhyThisMattersCard: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let kind: CollegeFootballClaimKind
    let groundedFactIDs: [String]
}

struct CollegeFootballRelatedSearchesCard: Equatable, Identifiable, Sendable {
    let id: String
    let searches: [String]
}

struct CollegeFootballHostReaction: Equatable, Identifiable, Sendable {
    let id: String
    let line: String
    let kind: CollegeFootballClaimKind
    let providerName: String
    let groundedFactIDs: [String]
    let behavior: HostBehavior
}

enum CollegeFootballResultModule: Equatable, Identifiable, Sendable {
    case hostReaction(CollegeFootballHostReaction)
    case player(CollegeFootballPlayerCard)
    case team(CollegeFootballTeamCard)
    case game(CollegeFootballGameCard)
    case standings(CollegeFootballStandingsCard)
    case highlight(CollegeFootballHighlightCard)
    case performance(CollegeFootballPerformanceCard)
    case comparison(CollegeFootballComparisonCard)
    case playerInsight(CollegeFootballPlayerInsightCard)
    case personalMemory(CollegeFootballPersonalMemoryCard)
    case whyThisMatters(CollegeFootballWhyThisMattersCard)
    case relatedSearches(CollegeFootballRelatedSearchesCard)
    case watchNext(CollegeFootballWatchNextCard)

    var id: String {
        switch self {
        case .hostReaction(let value): "host:\(value.id)"
        case .player(let value): "player:\(value.id)"
        case .team(let value): "team:\(value.id)"
        case .game(let value): "game:\(value.id)"
        case .standings(let value): "standings:\(value.id)"
        case .highlight(let value): "highlight:\(value.id)"
        case .performance(let value): "performance:\(value.id)"
        case .comparison(let value): "comparison:\(value.id)"
        case .playerInsight(let value): "player-insight:\(value.id)"
        case .personalMemory(let value): "memory:\(value.id)"
        case .whyThisMatters(let value): "why:\(value.id)"
        case .relatedSearches(let value): "related:\(value.id)"
        case .watchNext(let value): "watch:\(value.id)"
        }
    }

    var facts: [CollegeFootballFact] {
        switch self {
        case .player(let value): value.facts
        case .team(let value): value.facts
        case .game(let value): value.facts
        case .standings(let value): value.facts
        case .highlight(let value): value.facts
        case .performance(let value): value.facts
        case .comparison(let value): value.facts
        case .playerInsight(let value): value.facts
        case .personalMemory(let value): value.facts
        case .watchNext(let value): value.facts
        case .hostReaction, .whyThisMatters, .relatedSearches: []
        }
    }
}
