import Foundation

enum MockMichaelProfile {
    static let value = BaseballFanProfileSnapshot(
        id: "mock-michael",
        name: "Michael",
        favoriteTeam: "Colorado Rockies",
        favoritePlayers: ["Hunter Goodman"],
        rivalTeams: ["Los Angeles Dodgers"],
        interests: [
            .emergingPlayers,
            .standings,
            .playoffRaces,
            .baseballHistory,
            .condensedGames,
            .greatStories,
        ],
        stadiumVisits: [
            .init(
                id: "visit-coors",
                stadiumName: "Coors Field",
                city: "Denver",
                attendedAt: MockBaseballFixtures.fixtureDate.addingTimeInterval(-2_592_000)
            ),
            .init(
                id: "visit-oracle",
                stadiumName: "Oracle Park",
                city: "San Francisco",
                attendedAt: MockBaseballFixtures.fixtureDate.addingTimeInterval(-15_552_000)
            ),
            .init(
                id: "visit-wrigley",
                stadiumName: "Wrigley Field",
                city: "Chicago",
                attendedAt: MockBaseballFixtures.fixtureDate.addingTimeInterval(-31_536_000)
            ),
        ],
        frequentSearchThemes: [
            "Wild Card implications",
            "emerging Rockies players",
            "condensed games",
        ]
    )
}

enum MockBaseballFixtures {
    static let fixtureDate = Date(timeIntervalSince1970: 1_785_100_000)
    static let provenance = BaseballProvenance.prototypeFixture(asOf: fixtureDate)

    static func fact(_ id: String, _ statement: String) -> BaseballFact {
        BaseballFact(
            id: id,
            statement: statement,
            kind: .fact,
            provenance: provenance
        )
    }

    static let judge = BaseballPlayerCard(
        id: "aaron-judge",
        name: "Aaron Judge",
        teamName: "New York Yankees",
        position: "Outfielder",
        summary: "Prototype coverage includes his Yankees role and one illustrative contact-quality view. Live statistics and schedule data are not connected.",
        facts: [
            fact("judge-power", "Fixture: Judge’s result experience leads with power and contact quality."),
            fact("judge-role", "Fixture: Judge is listed as a New York Yankees outfielder in this prototype."),
        ]
    )

    static let ohtani = BaseballPlayerCard(
        id: "shohei-ohtani",
        name: "Shohei Ohtani",
        teamName: "Los Angeles Dodgers",
        position: "Designated hitter",
        summary: "Separate the roles: this fixture covers Ohtani as a hitter and does not guess at his pitching availability.",
        facts: [
            fact("ohtani-role", "Fixture: Ohtani is listed as designated hitter in this prototype."),
            fact("ohtani-pitching", "Fixture: The availability card explains that pitching status requires sourced context."),
        ]
    )

    static let goodman = BaseballPlayerCard(
        id: "hunter-goodman",
        name: "Hunter Goodman",
        teamName: "Colorado Rockies",
        position: "Catcher / first baseman",
        summary: "An emerging Rockies player matched to Michael’s favorite team and interest in players on the rise.",
        facts: [
            fact("goodman-emerging", "Fixture: Goodman is tagged as an emerging player for the demo profile."),
            fact("goodman-rockies", "Fixture: Goodman is connected to the profile’s favorite team."),
        ]
    )

    static let rockies = BaseballTeamCard(
        id: "colorado-rockies",
        name: "Colorado Rockies",
        abbreviation: "COL",
        summary: "The profile’s favorite team, with schedule and standings context prioritized.",
        facts: [
            fact("rockies-favorite", "Fixture: Colorado is the demo profile’s favorite team."),
            fact("rockies-tonight", "Fixture: Colorado has a home game in the prototype tonight slate."),
        ]
    )

    static let dodgers = BaseballTeamCard(
        id: "los-angeles-dodgers",
        name: "Los Angeles Dodgers",
        abbreviation: "LAD",
        summary: "A rival context card for the injected prototype profile.",
        facts: [
            fact("dodgers-rival", "Fixture: Los Angeles is configured as a rival team."),
            fact("dodgers-result", "Fixture: Los Angeles lost its previous prototype game."),
        ]
    )

    static let rockiesGame = BaseballGameCard(
        id: "rockies-dodgers-tonight",
        awayTeam: "Los Angeles Dodgers",
        homeTeam: "Colorado Rockies",
        venue: "Coors Field",
        startsAt: fixtureDate.addingTimeInterval(18_000),
        status: .scheduled,
        statusText: "Prototype schedule — not live",
        facts: [
            fact("game-scheduled", "Fixture: Rockies versus Dodgers is scheduled at Coors Field."),
            fact("game-favorite-rival", "Fixture: The game matches the profile’s favorite team with a configured rival."),
        ]
    )

    static let rockiesBrewersFinal = fact(
        "rockies-brewers-final",
        "Fixture: Milwaukee defeated Colorado 11–2; the Brewers had 14 hits and no errors, while the Rockies had five hits and one error."
    )

    static let standings = BaseballStandingsCard(
        id: "rockies-nl-west-standings",
        title: "Rockies are fifth in the NL West",
        summary: "Colorado is 42–65, has gone 3–7 in its last ten with a two-game losing streak, and owns MLB’s second-worst run differential at −110.",
        facts: [
            fact("standings-form", "Fixture: Colorado is fifth in the NL West at 42–65, 25.5 games back, with a 3–7 last-ten record and an L2 streak."),
            fact("standings-differential", "Fixture: Colorado’s −110 run differential is better only than the Athletics’ −127."),
            fact("standings-next", "Fixture: Colorado next plays San Diego at Petco Park on July 28 at 9:40 PM EDT, with Lorenzen and King listed as probable pitchers."),
        ]
    )

    static let highlight = BaseballHighlightCard(
        id: "rockies-condensed-highlight",
        title: "The Rockies sequence worth seeing",
        subtitle: "A fixture highlight selected for consequence, not just popularity.",
        durationSeconds: 74,
        facts: [
            fact("highlight-fixture", "Fixture: This condensed sequence is relevant to the profile’s Rockies interest."),
        ]
    )

    static let judgeStatcast = BaseballStatcastCard(
        id: "judge-contact-quality",
        title: "Why the contact jumps off the screen",
        metricName: "Prototype contact-quality index",
        metricValue: "Elite fixture band",
        explanation: "A visual placeholder for a future sourced Statcast comparison.",
        facts: [
            fact("statcast-fixture", "Fixture: The displayed Statcast band is illustrative and not a live measurement."),
        ]
    )

    static let comparison = BaseballComparisonCard(
        id: "judge-ohtani-comparison",
        leftName: "Aaron Judge",
        rightName: "Shohei Ohtani",
        headline: "Power shape, role, and watchability—without collapsing two different games into one number.",
        facts: [
            fact("comparison-judge", "Fixture: Judge’s comparison side emphasizes contact quality."),
            fact("comparison-ohtani", "Fixture: Ohtani’s comparison side separates hitting role from pitching availability."),
        ]
    )

    static let personalMemory = BaseballPersonalMemoryCard(
        id: "michael-last-rockies-game",
        title: "Your last Rockies game",
        detail: "Prototype attendance record at Coors Field.",
        occurredAt: fixtureDate.addingTimeInterval(-2_592_000),
        facts: [
            fact("memory-attendance", "Fixture: The profile’s most recent stored Rockies visit is at Coors Field."),
        ]
    )

    static let watchNext = BaseballWatchNextCard(
        id: "watch-rockies-condensed",
        title: "Watch the Rockies condensed game",
        reason: "It matches the profile’s favorite team and preference for condensed games with playoff context.",
        query: "What did I miss in the Rockies game?",
        facts: [
            fact("watch-fixture", "Fixture: The profile includes condensed games and playoff races."),
        ]
    )

    static let related = BaseballRelatedSearchesCard(
        id: "prototype-related",
        searches: [
            "Compare Judge and Ohtani",
            "How does tonight affect the Wild Card?",
            "Who should I watch?",
        ]
    )
}

struct MockBaseballDataService: BaseballDataProviding {
    func fetch(
        plan: BaseballSearchPlan,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballDataSnapshot {
        var modules: [BaseballResultModule] = []
        var seenIDs: Set<String> = []

        func append(_ module: BaseballResultModule) {
            guard seenIDs.insert(module.id).inserted else { return }
            modules.append(module)
        }

        for requestedModule in plan.requestedModules {
            switch requestedModule {
            case .player:
                let players = requestedPlayers(for: plan.query)
                let fallbackPlayers = plan.query.intent == .favoritePlayer
                    ? []
                    : [MockBaseballFixtures.goodman]
                (players.isEmpty ? fallbackPlayers : players).forEach {
                    append(.player($0))
                }
            case .team:
                if let team = requestedTeam(for: plan.query, profile: profile) {
                    append(.team(team))
                }
            case .game, .liveScore, .schedule:
                if supportsRockiesContext(plan.query) {
                    append(.game(MockBaseballFixtures.rockiesGame))
                }
            case .standings:
                if supportsRockiesContext(plan.query) {
                    append(.standings(MockBaseballFixtures.standings))
                }
            case .highlight:
                if supportsRockiesContext(plan.query) {
                    append(.highlight(MockBaseballFixtures.highlight))
                }
            case .statcast:
                if plan.query.entities.contains(where: { $0.id == "player-aaron-judge" }) {
                    append(.statcast(MockBaseballFixtures.judgeStatcast))
                }
            case .historicalComparison:
                append(.comparison(MockBaseballFixtures.comparison))
            case .personalMemory:
                append(.personalMemory(MockBaseballFixtures.personalMemory))
            case .relatedSearches:
                append(.relatedSearches(MockBaseballFixtures.related))
            case .watchNext:
                if supportsRockiesContext(plan.query) {
                    append(.watchNext(MockBaseballFixtures.watchNext))
                }
            case .hostReaction, .whyThisMatters, .fantasyImpact, .ticketOpportunity:
                break
            }
        }

        if modules.isEmpty, plan.query.intent != .unknown {
            throw BaseballSearchArchitectureError.noFixture(plan.query.rawText)
        }

        return BaseballDataSnapshot(
            plan: plan,
            modules: modules,
            supportingFacts: modules.flatMap(\.facts)
        )
    }

    private func requestedPlayers(for query: BaseballSearchQuery) -> [BaseballPlayerCard] {
        query.entities.compactMap { entity in
            switch entity.id {
            case "player-aaron-judge": MockBaseballFixtures.judge
            case "player-shohei-ohtani": MockBaseballFixtures.ohtani
            case "player-hunter-goodman": MockBaseballFixtures.goodman
            default: nil
            }
        }
    }

    private func supportsRockiesContext(_ query: BaseballSearchQuery) -> Bool {
        if query.entities.contains(where: {
            $0.id == "team-colorado-rockies"
                || $0.id == "team-los-angeles-dodgers"
                || $0.id == "player-hunter-goodman"
        }) {
            return true
        }

        switch query.intent {
        case .gamesTonight,
             .playerRecommendation,
             .missedGamesRecap,
             .standingsImpact,
             .personalAttendanceHistory,
             .watchNext:
            return true
        case .favoriteTeam,
             .favoritePlayer,
             .entityLookup,
             .teamLookup,
             .playerComparison,
             .availabilityExplanation,
             .unknown:
            return false
        }
    }

    private func requestedTeam(
        for query: BaseballSearchQuery,
        profile: BaseballFanProfileSnapshot
    ) -> BaseballTeamCard? {
        if query.entities.contains(where: { $0.id == "team-los-angeles-dodgers" }) {
            return MockBaseballFixtures.dodgers
        }
        if query.entities.contains(where: { $0.id == "team-colorado-rockies" })
            || profile.favoriteTeam == "Colorado Rockies" {
            return MockBaseballFixtures.rockies
        }
        return nil
    }
}

struct MockBaseballDiscoveryService: BaseballDiscoveryProviding {
    func cards(
        for profile: BaseballFanProfileSnapshot
    ) async throws -> [BaseballDiscoveryCard] {
        [
            BaseballDiscoveryCard(
                id: "discovery-rockies-tonight",
                eyebrow: "FINAL",
                title: "Rockies 2, Brewers 11",
                whyItMatters: "The final for \(profile.name)’s favorite team leads the experience.",
                systemImage: "baseball.diamond.bases",
                destinationQuery: "What did I miss yesterday?",
                hostBehavior: .concerned,
                facts: [MockBaseballFixtures.rockiesBrewersFinal],
                finalScore: BaseballFinalScoreSnapshot(
                    visitorTeam: "Rockies",
                    visitorAbbreviation: "CR",
                    visitorRecord: "42–65",
                    visitorRuns: 2,
                    visitorHits: 5,
                    visitorErrors: 1,
                    homeTeam: "Brewers",
                    homeAbbreviation: "M",
                    homeRecord: "66–39",
                    homeRuns: 11,
                    homeHits: 14,
                    homeErrors: 0,
                    winningPitcher: "Misiorowski",
                    winningPitcherLine: "11–4  |  1.58 ERA",
                    losingPitcher: "Freeland, K",
                    losingPitcherLine: "2–10  |  7.34 ERA"
                ),
                standings: nil
            ),
            BaseballDiscoveryCard(
                id: "discovery-standings",
                eyebrow: "NL WEST",
                title: "Rockies are fifth in the NL West",
                whyItMatters: "Recent form, run differential, and the next game explain where \(profile.name)’s team stands.",
                systemImage: "chart.line.uptrend.xyaxis",
                destinationQuery: "How does tonight affect the standings?",
                hostBehavior: .concerned,
                facts: MockBaseballFixtures.standings.facts,
                finalScore: nil,
                standings: BaseballStandingsSnapshot(
                    teamName: "Colorado Rockies",
                    teamAbbreviation: "COL",
                    division: "NL West",
                    divisionPosition: 5,
                    divisionTeamCount: 5,
                    record: "42–65",
                    gamesBack: "25.5",
                    lastTen: "3–7",
                    streak: "L2",
                    runDifferential: -110,
                    comparisonTeam: "Athletics",
                    comparisonTeamAbbreviation: "ATH",
                    comparisonRunDifferential: -127,
                    nextOpponent: "San Diego Padres",
                    nextOpponentAbbreviation: "SD",
                    nextOpponentRecord: "53–53",
                    nextOpponentDivisionPosition: 3,
                    nextGameDate: "Jul 28, 2026",
                    nextGameTime: "9:40 PM EDT",
                    nextGameVenue: "Petco Park",
                    probablePitchers: "Lorenzen vs King"
                )
            ),
            BaseballDiscoveryCard(
                id: "discovery-goodman",
                eyebrow: "EMERGING PLAYER",
                title: "Hunter Goodman is worth your next look",
                whyItMatters: "\(profile.name) follows emerging players and has Goodman among his favorites.",
                systemImage: "figure.baseball",
                destinationQuery: "Hunter Goodman",
                hostBehavior: .explain,
                facts: MockBaseballFixtures.goodman.facts,
                finalScore: nil,
                standings: nil
            ),
            BaseballDiscoveryCard(
                id: "discovery-dodgers-lost",
                eyebrow: "RIVAL WATCH",
                title: "The Dodgers lost",
                whyItMatters: "Los Angeles is a configured rival for \(profile.name), making this more relevant than generic news.",
                systemImage: "arrow.down.right.circle.fill",
                destinationQuery: "What does the Dodgers loss mean for the Rockies?",
                hostBehavior: .tease,
                facts: MockBaseballFixtures.dodgers.facts,
                finalScore: nil,
                standings: nil
            ),
            BaseballDiscoveryCard(
                id: "discovery-condensed",
                eyebrow: "WATCH NEXT",
                title: "Your condensed game is ready",
                whyItMatters: "\(profile.name) prefers condensed games, so the shortest meaningful watch gets priority.",
                systemImage: "play.rectangle.fill",
                destinationQuery: MockBaseballFixtures.watchNext.query,
                hostBehavior: .greet,
                facts: MockBaseballFixtures.watchNext.facts,
                finalScore: nil,
                standings: nil
            ),
        ]
    }
}
