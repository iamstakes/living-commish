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

enum BaseballCommishThoughts {
    static let onboarding =
        "Welcome! I'm the commish - your sports companion. "
        + "I can answer any question you have about baseball past or present. "
        + "Select your favorite teams and players and I will make sure that "
        + "your experience is new and fun on every visit!"

    static let rockiesBrewersFinal =
        "Dude, what can I say? The Brew crew was the better team last night."

    static let rockiesStandings =
        "Well, at least our run differential is better than the A's!"

    static let hunterGoodmanStory =
        "Good news? Goodman! He's a keeper. Check out his latest."
}

struct BaseballDiscoveryCard: Equatable, Identifiable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let whyItMatters: String
    let systemImage: String
    let destinationQuery: String
    let hostBehavior: HostBehavior
    let hostThought: String?
    let facts: [BaseballFact]
    let finalScore: BaseballFinalScoreSnapshot?
    let standings: BaseballStandingsSnapshot?
    let playerStory: BaseballPlayerStorySnapshot?
}

struct BaseballFinalScoreSnapshot: Equatable, Sendable {
    let visitorTeam: String
    let visitorAbbreviation: String
    let visitorRecord: String
    let visitorRuns: Int
    let visitorHits: Int
    let visitorErrors: Int
    let homeTeam: String
    let homeAbbreviation: String
    let homeRecord: String
    let homeRuns: Int
    let homeHits: Int
    let homeErrors: Int
    let winningPitcher: String
    let winningPitcherLine: String
    let losingPitcher: String
    let losingPitcherLine: String
}

struct BaseballStandingsSnapshot: Equatable, Sendable {
    let teamName: String
    let teamAbbreviation: String
    let division: String
    let divisionPosition: Int
    let divisionTeamCount: Int
    let record: String
    let gamesBack: String
    let lastTen: String
    let streak: String
    let runDifferential: Int
    let comparisonTeam: String
    let comparisonTeamAbbreviation: String
    let comparisonRunDifferential: Int
    let nextOpponent: String
    let nextOpponentAbbreviation: String
    let nextOpponentRecord: String
    let nextOpponentDivisionPosition: Int
    let nextGameDate: String
    let nextGameTime: String
    let nextGameVenue: String
    let probablePitchers: String
}

struct BaseballPlayerStorySnapshot: Equatable, Identifiable, Sendable {
    let id: String
    let kicker: String
    let playerName: String
    let teamName: String
    let headline: String
    let summary: String
    let imageURL: URL
    let sourceURL: URL
    let sourceName: String
    let highlights: [BaseballPlayerStoryHighlight]
}

struct BaseballPlayerStoryHighlight: Equatable, Identifiable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let date: String
    let metrics: [String]
}
