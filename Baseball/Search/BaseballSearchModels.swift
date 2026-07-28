import Foundation

enum BaseballInterest: String, CaseIterable, Codable, Sendable {
    case emergingPlayers
    case standings
    case playoffRaces
    case baseballHistory
    case condensedGames
    case greatStories
}

struct BaseballStadiumVisit: Equatable, Identifiable, Sendable {
    let id: String
    let stadiumName: String
    let city: String
    let attendedAt: Date
}

struct BaseballFanProfileSnapshot: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let favoriteTeam: String
    let favoritePlayers: [String]
    let rivalTeams: [String]
    let interests: Set<BaseballInterest>
    let stadiumVisits: [BaseballStadiumVisit]
    let frequentSearchThemes: [String]
}

enum BaseballEntityKind: String, Equatable, Sendable {
    case player
    case team
}

struct BaseballEntityReference: Equatable, Identifiable, Sendable {
    let id: String
    let kind: BaseballEntityKind
    let canonicalName: String
}

enum BaseballSearchIntent: String, CaseIterable, Equatable, Sendable {
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

enum BaseballTimeScope: String, Equatable, Sendable {
    case today
    case tonight
    case yesterday
    case upcoming
    case allTime
    case unspecified
}

struct BaseballSearchQuery: Equatable, Sendable {
    let rawText: String
    let intent: BaseballSearchIntent
    let entities: [BaseballEntityReference]
    let timeScope: BaseballTimeScope
    let requiresPersonalHistory: Bool
    let ambiguity: String?
}

enum BaseballResultModuleKind: String, CaseIterable, Equatable, Sendable {
    case hostReaction
    case player
    case team
    case game
    case liveScore
    case schedule
    case standings
    case highlight
    case statcast
    case historicalComparison
    case fantasyImpact
    case ticketOpportunity
    case personalMemory
    case whyThisMatters
    case relatedSearches
    case watchNext
}

struct BaseballSearchPlan: Equatable, Sendable {
    let query: BaseballSearchQuery
    let requestedModules: [BaseballResultModuleKind]
    let hostBehavior: HostBehavior
}

struct BaseballDataSnapshot: Equatable, Sendable {
    let plan: BaseballSearchPlan
    let modules: [BaseballResultModule]
    let supportingFacts: [BaseballFact]
}

struct BaseballHostEditorial: Equatable, Sendable {
    let reaction: BaseballHostReaction
    let whyThisMatters: BaseballWhyThisMattersCard
}

struct BaseballSearchExperience: Equatable, Sendable {
    let query: BaseballSearchQuery
    let modules: [BaseballResultModule]
    let generatedAt: Date
}

struct BaseballSearchFailurePresentation: Equatable, Sendable {
    let title: String
    let message: String
    let recoverySuggestions: [String]
}

enum BaseballSearchExperienceState: Equatable, Sendable {
    case discovering
    case interpreting(query: String)
    case loading(plan: BaseballSearchPlan)
    case presenting(BaseballSearchExperience)
    case failed(BaseballSearchFailurePresentation)
}

struct BaseballDiscoveryCard: Equatable, Identifiable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let whyItMatters: String
    let systemImage: String
    let destinationQuery: String
    let hostBehavior: HostBehavior
    let facts: [BaseballFact]
}
