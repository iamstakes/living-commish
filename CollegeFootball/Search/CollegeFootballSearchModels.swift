import Foundation

enum CollegeFootballInterest: String, CaseIterable, Codable, Sendable {
    case emergingPlayers
    case standings
    case playoffRaces
    case collegeFootballHistory
    case condensedGames
    case greatStories
}

struct CollegeFootballStadiumVisit: Equatable, Identifiable, Sendable {
    let id: String
    let stadiumName: String
    let city: String
    let attendedAt: Date
}

struct CollegeFootballFanProfileSnapshot: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let favoriteTeam: String
    let favoritePlayers: [String]
    let rivalTeams: [String]
    let interests: Set<CollegeFootballInterest>
    let stadiumVisits: [CollegeFootballStadiumVisit]
    let frequentSearchThemes: [String]
}

enum CollegeFootballEntityKind: String, Equatable, Sendable {
    case player
    case team
}

struct CollegeFootballEntityReference: Equatable, Identifiable, Sendable {
    let id: String
    let kind: CollegeFootballEntityKind
    let canonicalName: String
}

enum CollegeFootballSearchIntent: String, CaseIterable, Equatable, Sendable {
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

enum CollegeFootballTimeScope: String, Equatable, Sendable {
    case today
    case tonight
    case yesterday
    case upcoming
    case allTime
    case unspecified
}

struct CollegeFootballSearchQuery: Equatable, Sendable {
    let rawText: String
    let intent: CollegeFootballSearchIntent
    let entities: [CollegeFootballEntityReference]
    let timeScope: CollegeFootballTimeScope
    let requiresPersonalHistory: Bool
    let ambiguity: String?
}

enum CollegeFootballResultModuleKind: String, CaseIterable, Equatable, Sendable {
    case hostReaction
    case player
    case team
    case game
    case liveScore
    case schedule
    case standings
    case highlight
    case performance
    case historicalComparison
    case playerInsights
    case fantasyImpact
    case ticketOpportunity
    case personalMemory
    case whyThisMatters
    case relatedSearches
    case watchNext
}

struct CollegeFootballSearchPlan: Equatable, Sendable {
    let query: CollegeFootballSearchQuery
    let requestedModules: [CollegeFootballResultModuleKind]
    let hostBehavior: HostBehavior
}

struct CollegeFootballDataSnapshot: Equatable, Sendable {
    let plan: CollegeFootballSearchPlan
    let modules: [CollegeFootballResultModule]
    let supportingFacts: [CollegeFootballFact]
}

struct CollegeFootballHostEditorial: Equatable, Sendable {
    let reaction: CollegeFootballHostReaction
    let whyThisMatters: CollegeFootballWhyThisMattersCard
}

struct CollegeFootballSearchExperience: Equatable, Sendable {
    let query: CollegeFootballSearchQuery
    let modules: [CollegeFootballResultModule]
    let generatedAt: Date
}

struct CollegeFootballSearchFailurePresentation: Equatable, Sendable {
    let title: String
    let message: String
    let recoverySuggestions: [String]
}

enum CollegeFootballSearchExperienceState: Equatable, Sendable {
    case discovering
    case interpreting(query: String)
    case loading(plan: CollegeFootballSearchPlan)
    case presenting(CollegeFootballSearchExperience)
    case failed(CollegeFootballSearchFailurePresentation)
}

enum CollegeFootballCommishThoughts {
    static let onboarding =
        "Welcome! I’m your college football companion. Saturdays, stories, and rivalries—organized around your fandom."

    static let buffsRivalry =
        "Black and gold. Red across the line. Yeah—this one still matters."

    static let buffsPlayoffPath =
        "Conference wins are the currency now. Let’s map the road to December."

    static let travisHunterStory =
        "One side of the ball was never going to be enough. Open the full Hunter story."
}

struct CollegeFootballDiscoveryCard: Equatable, Identifiable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let whyItMatters: String
    let systemImage: String
    let destinationQuery: String
    let hostBehavior: HostBehavior
    let hostThought: String?
    let facts: [CollegeFootballFact]
    let finalScore: CollegeFootballFinalScoreSnapshot?
    let standings: CollegeFootballStandingsSnapshot?
    let playerStory: CollegeFootballPlayerStorySnapshot?
    let dailyDrop: CollegeFootballDailyDrop?
}

struct CollegeFootballFinalScoreSnapshot: Equatable, Sendable {
    let visitorTeam: String
    let visitorAbbreviation: String
    let visitorRecord: String
    let visitorPoints: Int
    let visitorFirstDowns: Int
    let visitorTurnovers: Int
    let homeTeam: String
    let homeAbbreviation: String
    let homeRecord: String
    let homePoints: Int
    let homeFirstDowns: Int
    let homeTurnovers: Int
    let winningLeader: String
    let winningLeaderLine: String
    let losingLeader: String
    let losingLeaderLine: String
}

struct CollegeFootballStandingsSnapshot: Equatable, Sendable {
    let teamName: String
    let teamAbbreviation: String
    let division: String
    let divisionPosition: Int
    let divisionTeamCount: Int
    let record: String
    let conferenceRecord: String
    let rankedRecord: String
    let streak: String
    let pointDifferential: Int
    let comparisonTeam: String
    let comparisonTeamAbbreviation: String
    let comparisonPointDifferential: Int
    let nextOpponent: String
    let nextOpponentAbbreviation: String
    let nextOpponentRecord: String
    let nextOpponentConferencePosition: Int
    let nextGameDate: String
    let nextGameTime: String
    let nextGameVenue: String
    let broadcastNote: String
}

struct CollegeFootballPlayerStorySnapshot: Equatable, Identifiable, Sendable {
    let id: String
    let kicker: String
    let playerName: String
    let teamName: String
    let headline: String
    let summary: String
    let imageURL: URL
    let sourceURL: URL
    let sourceName: String
    let highlights: [CollegeFootballPlayerStoryHighlight]
}

struct CollegeFootballPlayerStoryHighlight: Equatable, Identifiable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let date: String
    let metrics: [String]
}
