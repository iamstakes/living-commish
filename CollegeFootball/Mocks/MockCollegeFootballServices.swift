import Foundation

enum MockMichaelProfile {
    static let value = CollegeFootballFanProfileSnapshot(
        id: "mock-michael",
        name: "Michael",
        favoriteTeam: "Colorado Buffaloes",
        favoritePlayers: ["Travis Hunter"],
        rivalTeams: ["Nebraska Cornhuskers"],
        interests: [
            .emergingPlayers,
            .standings,
            .playoffRaces,
            .collegeFootballHistory,
            .condensedGames,
            .greatStories,
        ],
        stadiumVisits: [
            .init(
                id: "visit-folsom",
                stadiumName: "Folsom Field",
                city: "Boulder",
                attendedAt: MockCollegeFootballFixtures.fixtureDate
                    .addingTimeInterval(-2_592_000)
            ),
            .init(
                id: "visit-memorial-nebraska",
                stadiumName: "Memorial Stadium",
                city: "Lincoln",
                attendedAt: MockCollegeFootballFixtures.fixtureDate
                    .addingTimeInterval(-15_552_000)
            ),
            .init(
                id: "visit-rose-bowl",
                stadiumName: "Rose Bowl",
                city: "Pasadena",
                attendedAt: MockCollegeFootballFixtures.fixtureDate
                    .addingTimeInterval(-31_536_000)
            ),
        ],
        frequentSearchThemes: [
            "College Football Playoff implications",
            "Colorado players",
            "rivalry games",
        ]
    )
}

enum MockCollegeFootballFixtures {
    static let fixtureDate = Date(timeIntervalSince1970: 1_785_100_000)
    static let prototypeProvenance = CollegeFootballProvenance
        .prototypeFixture(asOf: fixtureDate)
    static let coloradoProvenance = CollegeFootballProvenance(
        sourceName: "University of Colorado Athletics",
        asOf: fixtureDate,
        isMock: false
    )
    static let heismanProvenance = CollegeFootballProvenance(
        sourceName: "Heisman Trophy Trust",
        asOf: fixtureDate,
        isMock: false
    )

    static func fact(_ id: String, _ statement: String) -> CollegeFootballFact {
        CollegeFootballFact(
            id: id,
            statement: statement,
            kind: .fact,
            provenance: prototypeProvenance
        )
    }

    static func sourcedFact(
        _ id: String,
        _ statement: String,
        provenance: CollegeFootballProvenance
    ) -> CollegeFootballFact {
        CollegeFootballFact(
            id: id,
            statement: statement,
            kind: .fact,
            provenance: provenance
        )
    }

    static let travisHunter = CollegeFootballPlayerCard(
        id: "travis-hunter",
        name: "Travis Hunter",
        teamName: "Colorado Buffaloes",
        position: "Cornerback / wide receiver",
        summary: "The 2024 Heisman winner turned a full-time two-way workload into one of college football’s most decorated seasons.",
        facts: [
            sourcedFact(
                "hunter-heisman",
                "Travis Hunter won the 2024 Heisman Trophy and became Colorado’s second winner.",
                provenance: heismanProvenance
            ),
            sourcedFact(
                "hunter-two-way",
                "Colorado lists Hunter’s 2024 regular-season totals as 92 receptions, 1,152 receiving yards, 14 receiving touchdowns, four interceptions, and 11 pass breakups.",
                provenance: coloradoProvenance
            ),
        ],
        gallery: [
            CollegeFootballPlayerGalleryImage(
                id: "hunter-heisman-night",
                title: "The Heisman Moment",
                caption: "Hunter became Colorado’s second Heisman winner, thirty years after Rashaan Salaam.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/12/14/img_24989749_oN2iB.jpg",
                sourceName: "University of Colorado Athletics"
            ),
            CollegeFootballPlayerGalleryImage(
                id: "hunter-cincinnati",
                title: "A Receiver’s Production",
                caption: "He led the Big 12 with 92 catches and 14 receiving touchdowns during the 2024 regular season.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/10/29/CUFB_v.Cincy_Selects_ATS-49.jpg",
                sourceName: "University of Colorado Athletics"
            ),
            CollegeFootballPlayerGalleryImage(
                id: "hunter-tcu",
                title: "A Corner’s Instincts",
                caption: "The same season included four interceptions, 11 pass breakups, and Big 12 Defensive Player of the Year honors.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2023/9/6/Hunter_09022023-TCU-Selects-194.jpg",
                sourceName: "University of Colorado Athletics"
            ),
            CollegeFootballPlayerGalleryImage(
                id: "hunter-two-way-workload",
                title: "Both Sides, Every Saturday",
                caption: "Colorado credits Hunter with more than 2,600 snaps across his two seasons in Boulder.",
                imageURL: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2023/9/5/img_21332353.jpg",
                sourceName: "University of Colorado Athletics"
            ),
        ],
        quiz: CollegeFootballDailyDropCatalog.travisHunterQuiz
    )

    static let shedeurSanders = CollegeFootballPlayerCard(
        id: "shedeur-sanders",
        name: "Shedeur Sanders",
        teamName: "Colorado Buffaloes",
        position: "Quarterback",
        summary: "Colorado’s record-setting passer gives the Hunter story its offensive context and another natural path into the 2024 Buffaloes.",
        facts: [
            fact(
                "shedeur-profile",
                "Fixture: Shedeur Sanders is included as a Colorado quarterback search example."
            ),
        ],
        gallery: [],
        quiz: nil
    )

    static let ashtonJeanty = CollegeFootballPlayerCard(
        id: "ashton-jeanty",
        name: "Ashton Jeanty",
        teamName: "Boise State Broncos",
        position: "Running back",
        summary: "The 2024 Heisman runner-up offers the cleanest same-season contrast to Hunter’s two-way case.",
        facts: [
            sourcedFact(
                "jeanty-heisman-runner-up",
                "Ashton Jeanty finished second to Travis Hunter in 2024 Heisman voting.",
                provenance: heismanProvenance
            ),
        ],
        gallery: [],
        quiz: nil
    )

    static let charlesWoodson = CollegeFootballPlayerCard(
        id: "charles-woodson",
        name: "Charles Woodson",
        teamName: "Michigan Wolverines",
        position: "Cornerback / returner / wide receiver",
        summary: "Woodson’s 1997 Heisman season is the natural historical reference point for a defensive star contributing in all three phases.",
        facts: [
            sourcedFact(
                "woodson-heisman",
                "Charles Woodson won the 1997 Heisman Trophy.",
                provenance: heismanProvenance
            ),
        ],
        gallery: [],
        quiz: nil
    )

    static let travisHunterInsights = [
        CollegeFootballPlayerInsightCard(
            id: "hunter-two-way-stats",
            kind: .careerStats,
            title: "A two-way stat line",
            headline: "92 REC • 14 TD • 4 INT",
            summary: "Hunter produced elite receiver volume while remaining a shutdown corner throughout his Heisman season.",
            facts: travisHunter.facts
        ),
        CollegeFootballPlayerInsightCard(
            id: "hunter-woodson-comparison",
            kind: .modernComparison,
            title: "The two-way Heisman lineage",
            headline: "Travis Hunter × Charles Woodson",
            summary: "Woodson supplied the historical blueprint. Hunter expanded it into a full-time workload on offense and defense.",
            facts: [
                sourcedFact(
                    "two-way-heisman-lineage",
                    "Hunter won the Heisman in 2024; Woodson won it in 1997.",
                    provenance: heismanProvenance
                ),
            ]
        ),
        CollegeFootballPlayerInsightCard(
            id: "hunter-colorado-legacy",
            kind: .hallOfFameLegacy,
            title: "A Colorado first",
            headline: "First-team offense and defense",
            summary: "Hunter became the first player in Walter Camp All-America history to earn first-team honors on both sides of the ball.",
            facts: [
                sourcedFact(
                    "hunter-walter-camp-first",
                    "Colorado reports that Hunter was the first player in Walter Camp All-America history named first team on both offense and defense.",
                    provenance: coloradoProvenance
                ),
            ]
        ),
    ]

    static let hunterPlayerStoryFacts = [
        sourcedFact(
            "hunter-story-heisman",
            "Hunter became Colorado’s second Heisman winner in 2024.",
            provenance: coloradoProvenance
        ),
        sourcedFact(
            "hunter-story-receiving",
            "Hunter recorded 92 catches, 1,152 receiving yards, and 14 receiving touchdowns in the 2024 regular season.",
            provenance: coloradoProvenance
        ),
        sourcedFact(
            "hunter-story-defense",
            "Hunter added four interceptions and 11 pass breakups on defense in the 2024 regular season.",
            provenance: coloradoProvenance
        ),
    ]

    static let buffsHistoryQuizFacts = [
        sourcedFact(
            "buffs-1990-title",
            "Colorado’s 11–1–1 1990 team won the program’s first national football championship.",
            provenance: coloradoProvenance
        ),
        sourcedFact(
            "folsom-since-1924",
            "Folsom Field opened in 1924 and has served as Colorado’s football home ever since.",
            provenance: coloradoProvenance
        ),
        sourcedFact(
            "salaam-first-heisman",
            "Rashaan Salaam became Colorado’s first Heisman winner in 1994 after rushing for 2,055 yards.",
            provenance: coloradoProvenance
        ),
    ]

    static let buffaloes = CollegeFootballTeamCard(
        id: "colorado-buffaloes",
        name: "Colorado Buffaloes",
        abbreviation: "COLO",
        summary: "Michael’s favorite program, with Big 12, rivalry, player, and history context prioritized.",
        facts: [
            fact("buffs-favorite", "Fixture: Colorado is the demo profile’s favorite program."),
            fact("buffs-big-12", "Fixture: Colorado is presented in Big 12 context."),
        ]
    )

    static let nebraska = CollegeFootballTeamCard(
        id: "nebraska-cornhuskers",
        name: "Nebraska Cornhuskers",
        abbreviation: "NEB",
        summary: "A historic rival used to make team context more personal than a generic national feed.",
        facts: [
            fact("nebraska-rival", "Fixture: Nebraska is configured as a rival program."),
        ]
    )

    static let buffaloesGame = CollegeFootballGameCard(
        id: "buffaloes-nebraska-rivalry",
        awayTeam: "Nebraska Cornhuskers",
        homeTeam: "Colorado Buffaloes",
        venue: "Folsom Field",
        startsAt: fixtureDate.addingTimeInterval(18_000),
        status: .scheduled,
        statusText: "Prototype schedule — connect live provider",
        facts: [
            fact("game-scheduled", "Fixture: Colorado versus Nebraska is scheduled at Folsom Field."),
            fact("game-rival", "Fixture: The matchup connects the profile’s favorite program with a configured rival."),
        ]
    )

    static let standings = CollegeFootballStandingsCard(
        id: "buffaloes-big-12-outlook",
        title: "The Big 12 road starts here",
        summary: "Conference race, ranked wins, and the playoff path will replace generic standings once the live provider is connected.",
        facts: [
            fact("standings-fixture", "Fixture: The prototype ranks Colorado’s conference context ahead of national noise."),
        ]
    )

    static let highlight = CollegeFootballHighlightCard(
        id: "hunter-two-way-highlight",
        title: "Hunter’s two-way sequence worth seeing",
        subtitle: "A receiver win, a coverage rep, and the snap-to-snap workload that connects them.",
        durationSeconds: 92,
        facts: hunterPlayerStoryFacts
    )

    static let performance = CollegeFootballPerformanceCard(
        id: "hunter-two-way-workload",
        title: "Why the workload changed the award race",
        metricName: "Regular-season scrimmage snaps",
        metricValue: "1,356",
        explanation: "Colorado reported 670 offensive and 686 defensive snaps before the bowl game.",
        facts: [
            sourcedFact(
                "hunter-snap-count",
                "Colorado reported 670 offensive and 686 defensive snaps for Hunter during the 2024 regular season.",
                provenance: coloradoProvenance
            ),
        ]
    )

    static let comparison = CollegeFootballComparisonCard(
        id: "hunter-jeanty-comparison",
        leftName: "Travis Hunter",
        rightName: "Ashton Jeanty",
        headline: "A two-way season against a historic rushing season—the debate that defined the 2024 Heisman race.",
        facts: [
            sourcedFact(
                "heisman-2024-finish",
                "Hunter finished first and Jeanty second in 2024 Heisman voting.",
                provenance: heismanProvenance
            ),
        ]
    )

    static let personalMemory = CollegeFootballPersonalMemoryCard(
        id: "michael-last-buffs-game",
        title: "Your last Buffs game",
        detail: "Prototype attendance memory at Folsom Field in Boulder.",
        occurredAt: fixtureDate.addingTimeInterval(-2_592_000),
        facts: [
            fact("memory-attendance", "Fixture: The profile’s most recent stored Colorado visit is at Folsom Field."),
        ]
    )

    static let watchNext = CollegeFootballWatchNextCard(
        id: "watch-hunter-two-way",
        title: "Watch Hunter’s two-way masterclass",
        reason: "It matches the profile’s Colorado fandom and preference for defining player stories.",
        query: "Show me Travis Hunter’s two-way story",
        facts: hunterPlayerStoryFacts
    )

    static let related = CollegeFootballRelatedSearchesCard(
        id: "prototype-related",
        searches: [
            "Compare Travis Hunter and Ashton Jeanty",
            "What is Colorado’s playoff path?",
            "Who should I watch this Saturday?",
        ]
    )
}

struct MockCollegeFootballDataService: CollegeFootballDataProviding {
    func fetch(
        plan: CollegeFootballSearchPlan,
        profile: CollegeFootballFanProfileSnapshot
    ) async throws -> CollegeFootballDataSnapshot {
        var modules: [CollegeFootballResultModule] = []
        var seenIDs: Set<String> = []

        func append(_ module: CollegeFootballResultModule) {
            guard seenIDs.insert(module.id).inserted else { return }
            modules.append(module)
        }

        for requestedModule in plan.requestedModules {
            switch requestedModule {
            case .player:
                let players = requestedPlayers(for: plan.query)
                let fallback = plan.query.intent == .favoritePlayer
                    ? []
                    : [MockCollegeFootballFixtures.travisHunter]
                (players.isEmpty ? fallback : players).forEach {
                    append(.player($0))
                }
            case .team:
                if let team = requestedTeam(for: plan.query, profile: profile) {
                    append(.team(team))
                }
            case .game, .liveScore, .schedule:
                if supportsBuffsContext(plan.query) {
                    append(.game(MockCollegeFootballFixtures.buffaloesGame))
                }
            case .standings:
                if supportsBuffsContext(plan.query) {
                    append(.standings(MockCollegeFootballFixtures.standings))
                }
            case .highlight:
                if supportsBuffsContext(plan.query) {
                    append(.highlight(MockCollegeFootballFixtures.highlight))
                }
            case .performance:
                if plan.query.entities.contains(where: {
                    $0.id == "player-travis-hunter"
                }) {
                    append(.performance(MockCollegeFootballFixtures.performance))
                }
            case .historicalComparison:
                append(.comparison(MockCollegeFootballFixtures.comparison))
            case .playerInsights:
                if plan.query.entities.contains(where: {
                    $0.id == "player-travis-hunter"
                }) {
                    MockCollegeFootballFixtures.travisHunterInsights.forEach {
                        append(.playerInsight($0))
                    }
                }
            case .personalMemory:
                append(.personalMemory(MockCollegeFootballFixtures.personalMemory))
            case .relatedSearches:
                append(.relatedSearches(MockCollegeFootballFixtures.related))
            case .watchNext:
                if supportsBuffsContext(plan.query) {
                    append(.watchNext(MockCollegeFootballFixtures.watchNext))
                }
            case .hostReaction, .whyThisMatters, .fantasyImpact, .ticketOpportunity:
                break
            }
        }

        if modules.isEmpty, plan.query.intent != .unknown {
            throw CollegeFootballSearchArchitectureError.noFixture(plan.query.rawText)
        }

        return CollegeFootballDataSnapshot(
            plan: plan,
            modules: modules,
            supportingFacts: modules.flatMap(\.facts)
        )
    }

    private func requestedPlayers(
        for query: CollegeFootballSearchQuery
    ) -> [CollegeFootballPlayerCard] {
        query.entities.compactMap { entity in
            switch entity.id {
            case "player-travis-hunter": MockCollegeFootballFixtures.travisHunter
            case "player-shedeur-sanders": MockCollegeFootballFixtures.shedeurSanders
            case "player-ashton-jeanty": MockCollegeFootballFixtures.ashtonJeanty
            case "player-charles-woodson": MockCollegeFootballFixtures.charlesWoodson
            default: nil
            }
        }
    }

    private func supportsBuffsContext(_ query: CollegeFootballSearchQuery) -> Bool {
        if query.entities.contains(where: {
            $0.id == "team-colorado-buffaloes"
                || $0.id == "team-nebraska-cornhuskers"
                || $0.id == "player-travis-hunter"
                || $0.id == "player-shedeur-sanders"
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
        for query: CollegeFootballSearchQuery,
        profile: CollegeFootballFanProfileSnapshot
    ) -> CollegeFootballTeamCard? {
        if query.entities.contains(where: {
            $0.id == "team-nebraska-cornhuskers"
        }) {
            return MockCollegeFootballFixtures.nebraska
        }
        if query.entities.contains(where: {
            $0.id == "team-colorado-buffaloes"
        }) || profile.favoriteTeam == "Colorado Buffaloes" {
            return MockCollegeFootballFixtures.buffaloes
        }
        return nil
    }
}

struct MockCollegeFootballDiscoveryService: CollegeFootballDiscoveryProviding {
    func cards(
        for profile: CollegeFootballFanProfileSnapshot
    ) async throws -> [CollegeFootballDiscoveryCard] {
        guard profile.favoriteTeam == "Colorado Buffaloes" else {
            return genericCards(for: profile)
        }

        return [
            CollegeFootballDiscoveryCard(
                id: "discovery-buffs-kickoff",
                eyebrow: "SATURDAY STARTS HERE",
                title: "Buffs vs. Nebraska at Folsom",
                whyItMatters: "The next rivalry game for \(profile.name)’s favorite program leads the experience.",
                systemImage: "football.fill",
                destinationQuery: "Colorado Buffaloes next game",
                hostBehavior: .interrupt,
                hostThought: CollegeFootballCommishThoughts.buffsRivalry,
                facts: MockCollegeFootballFixtures.buffaloesGame.facts,
                finalScore: nil,
                standings: nil,
                playerStory: nil,
                dailyDrop: nil
            ),
            CollegeFootballDiscoveryCard(
                id: "discovery-big-12",
                eyebrow: "BIG 12 OUTLOOK",
                title: "The road to December",
                whyItMatters: "Conference stakes and the playoff path explain which Saturdays matter most.",
                systemImage: "chart.line.uptrend.xyaxis",
                destinationQuery: "What is Colorado’s playoff path?",
                hostBehavior: .explain,
                hostThought: CollegeFootballCommishThoughts.buffsPlayoffPath,
                facts: MockCollegeFootballFixtures.standings.facts,
                finalScore: nil,
                standings: nil,
                playerStory: nil,
                dailyDrop: nil
            ),
            CollegeFootballDiscoveryCard(
                id: "discovery-hunter-story",
                eyebrow: "PLAYER STORY",
                title: "The season one position couldn’t contain",
                whyItMatters: profile.favoritePlayers.contains("Travis Hunter")
                    ? "Hunter is one of \(profile.name)’s favorite players, and his two-way Heisman season deserves the full story."
                    : "Hunter’s two-way Heisman season is a defining Colorado story.",
                systemImage: "figure.american.football",
                destinationQuery: "Travis Hunter",
                hostBehavior: .celebrate,
                hostThought: CollegeFootballCommishThoughts.travisHunterStory,
                facts: MockCollegeFootballFixtures.hunterPlayerStoryFacts,
                finalScore: nil,
                standings: nil,
                playerStory: CollegeFootballPlayerStorySnapshot(
                    id: "cu-travis-hunter-heisman",
                    kicker: "PLAYER STORY",
                    playerName: "Travis Hunter",
                    teamName: "Colorado Buffaloes",
                    headline: "The season one position couldn’t contain",
                    summary: "The catches, interceptions, workload, and awards behind college football’s defining two-way season.",
                    imageURL: URL(
                        string: "https://dxbhsrqyrr690.cloudfront.net/sidearm.nextgen.sites/cubuffs.com/images/2024/10/29/CUFB_v.Cincy_Selects_ATS-49.jpg"
                    )!,
                    sourceURL: URL(
                        string: "https://cubuffs.com/news/2024/12/14/football-colorados-travis-hunter-wins-heisman-trophy"
                    )!,
                    sourceName: "University of Colorado Athletics",
                    highlights: [
                        CollegeFootballPlayerStoryHighlight(
                            id: "hunter-receiver",
                            eyebrow: "OFFENSE",
                            title: "Big 12 leader in catches and receiving TDs",
                            date: "2024 regular season",
                            metrics: ["92 REC", "1,152 YDS", "14 TD"]
                        ),
                        CollegeFootballPlayerStoryHighlight(
                            id: "hunter-corner",
                            eyebrow: "DEFENSE",
                            title: "A shutdown corner on the other side",
                            date: "2024 regular season",
                            metrics: ["4 INT", "11 PBU", "31 TKL"]
                        ),
                        CollegeFootballPlayerStoryHighlight(
                            id: "hunter-workload",
                            eyebrow: "TWO-WAY LOAD",
                            title: "Full-time snaps on offense and defense",
                            date: "Before the bowl game",
                            metrics: ["670 OFF", "686 DEF"]
                        ),
                        CollegeFootballPlayerStoryHighlight(
                            id: "hunter-heisman",
                            eyebrow: "THE RESULT",
                            title: "Colorado’s second Heisman Trophy",
                            date: "Dec 14, 2024",
                            metrics: ["552 1ST", "2,231 PTS"]
                        ),
                    ]
                ),
                dailyDrop: nil
            ),
            CollegeFootballDiscoveryCard(
                id: "discovery-daily-drop",
                eyebrow: "DAILY DROP",
                title: CollegeFootballDailyDropCatalog.buffsHistoryQuiz.title,
                whyItMatters: "A brand-new Colorado football history quiz unlocks a rare collectible for \(profile.name).",
                systemImage: "sparkles",
                destinationQuery: "Colorado Buffaloes history",
                hostBehavior: .think,
                hostThought: CollegeFootballDailyDropCatalog
                    .buffsHistoryQuiz
                    .hostThought,
                facts: MockCollegeFootballFixtures.buffsHistoryQuizFacts,
                finalScore: nil,
                standings: nil,
                playerStory: nil,
                dailyDrop: CollegeFootballDailyDropCatalog.buffsHistoryQuiz
            ),
            CollegeFootballDiscoveryCard(
                id: "discovery-rival-watch",
                eyebrow: "RIVALRY WATCH",
                title: "Why Nebraska still matters",
                whyItMatters: "Nebraska is configured as a rival for \(profile.name), so the history and stakes outrank generic national chatter.",
                systemImage: "bolt.horizontal.circle.fill",
                destinationQuery: "Colorado vs Nebraska rivalry",
                hostBehavior: .tease,
                hostThought: nil,
                facts: MockCollegeFootballFixtures.nebraska.facts,
                finalScore: nil,
                standings: nil,
                playerStory: nil,
                dailyDrop: nil
            ),
            CollegeFootballDiscoveryCard(
                id: "discovery-watch-next",
                eyebrow: "WATCH NEXT",
                title: "Hunter’s two-way cut is ready",
                whyItMatters: "\(profile.name) prefers defining stories, so the shortest meaningful watch gets priority.",
                systemImage: "play.rectangle.fill",
                destinationQuery: MockCollegeFootballFixtures.watchNext.query,
                hostBehavior: .greet,
                hostThought: nil,
                facts: MockCollegeFootballFixtures.watchNext.facts,
                finalScore: nil,
                standings: nil,
                playerStory: nil,
                dailyDrop: nil
            ),
        ]
    }

    private func genericCards(
        for profile: CollegeFootballFanProfileSnapshot
    ) -> [CollegeFootballDiscoveryCard] {
        let favoritePlayer = profile.favoritePlayers.first
            ?? "Favorite player not selected"
        return [
            CollegeFootballDiscoveryCard(
                id: "discovery-profile-team",
                eyebrow: "YOUR PROGRAM",
                title: profile.favoriteTeam,
                whyItMatters: "\(profile.name)’s program now leads the experience. Live team cards are the next provider integration.",
                systemImage: "shield.lefthalf.filled",
                destinationQuery: profile.favoriteTeam,
                hostBehavior: .greet,
                hostThought: nil,
                facts: [],
                finalScore: nil,
                standings: nil,
                playerStory: nil,
                dailyDrop: nil
            ),
            CollegeFootballDiscoveryCard(
                id: "discovery-profile-player",
                eyebrow: "YOUR PLAYER",
                title: favoritePlayer,
                whyItMatters: "Player stories and Saturday context will be ranked around this profile choice.",
                systemImage: "figure.american.football",
                destinationQuery: favoritePlayer,
                hostBehavior: .celebrate,
                hostThought: nil,
                facts: [],
                finalScore: nil,
                standings: nil,
                playerStory: nil,
                dailyDrop: nil
            ),
        ]
    }
}
