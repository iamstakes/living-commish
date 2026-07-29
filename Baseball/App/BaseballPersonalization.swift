import Foundation
import Observation

struct BaseballTeamChoice: Equatable, Identifiable, Sendable {
    let id: String
    let mlbID: Int
    let city: String
    let name: String
    let abbreviation: String
    let division: String

    var fullName: String {
        city.isEmpty ? name : "\(city) \(name)"
    }

    static let coloradoRockies = BaseballTeamChoice(
        id: "colorado-rockies",
        mlbID: 115,
        city: "Colorado",
        name: "Rockies",
        abbreviation: "COL",
        division: "NL West"
    )

    static let all: [BaseballTeamChoice] = [
        .init(id: "arizona-diamondbacks", mlbID: 109, city: "Arizona", name: "Diamondbacks", abbreviation: "AZ", division: "NL West"),
        .init(id: "athletics", mlbID: 133, city: "", name: "Athletics", abbreviation: "ATH", division: "AL West"),
        .init(id: "atlanta-braves", mlbID: 144, city: "Atlanta", name: "Braves", abbreviation: "ATL", division: "NL East"),
        .init(id: "baltimore-orioles", mlbID: 110, city: "Baltimore", name: "Orioles", abbreviation: "BAL", division: "AL East"),
        .init(id: "boston-red-sox", mlbID: 111, city: "Boston", name: "Red Sox", abbreviation: "BOS", division: "AL East"),
        .init(id: "chicago-cubs", mlbID: 112, city: "Chicago", name: "Cubs", abbreviation: "CHC", division: "NL Central"),
        .init(id: "chicago-white-sox", mlbID: 145, city: "Chicago", name: "White Sox", abbreviation: "CWS", division: "AL Central"),
        .init(id: "cincinnati-reds", mlbID: 113, city: "Cincinnati", name: "Reds", abbreviation: "CIN", division: "NL Central"),
        .init(id: "cleveland-guardians", mlbID: 114, city: "Cleveland", name: "Guardians", abbreviation: "CLE", division: "AL Central"),
        .coloradoRockies,
        .init(id: "detroit-tigers", mlbID: 116, city: "Detroit", name: "Tigers", abbreviation: "DET", division: "AL Central"),
        .init(id: "houston-astros", mlbID: 117, city: "Houston", name: "Astros", abbreviation: "HOU", division: "AL West"),
        .init(id: "kansas-city-royals", mlbID: 118, city: "Kansas City", name: "Royals", abbreviation: "KC", division: "AL Central"),
        .init(id: "los-angeles-angels", mlbID: 108, city: "Los Angeles", name: "Angels", abbreviation: "LAA", division: "AL West"),
        .init(id: "los-angeles-dodgers", mlbID: 119, city: "Los Angeles", name: "Dodgers", abbreviation: "LAD", division: "NL West"),
        .init(id: "miami-marlins", mlbID: 146, city: "Miami", name: "Marlins", abbreviation: "MIA", division: "NL East"),
        .init(id: "milwaukee-brewers", mlbID: 158, city: "Milwaukee", name: "Brewers", abbreviation: "MIL", division: "NL Central"),
        .init(id: "minnesota-twins", mlbID: 142, city: "Minnesota", name: "Twins", abbreviation: "MIN", division: "AL Central"),
        .init(id: "new-york-mets", mlbID: 121, city: "New York", name: "Mets", abbreviation: "NYM", division: "NL East"),
        .init(id: "new-york-yankees", mlbID: 147, city: "New York", name: "Yankees", abbreviation: "NYY", division: "AL East"),
        .init(id: "philadelphia-phillies", mlbID: 143, city: "Philadelphia", name: "Phillies", abbreviation: "PHI", division: "NL East"),
        .init(id: "pittsburgh-pirates", mlbID: 134, city: "Pittsburgh", name: "Pirates", abbreviation: "PIT", division: "NL Central"),
        .init(id: "san-diego-padres", mlbID: 135, city: "San Diego", name: "Padres", abbreviation: "SD", division: "NL West"),
        .init(id: "san-francisco-giants", mlbID: 137, city: "San Francisco", name: "Giants", abbreviation: "SF", division: "NL West"),
        .init(id: "seattle-mariners", mlbID: 136, city: "Seattle", name: "Mariners", abbreviation: "SEA", division: "AL West"),
        .init(id: "st-louis-cardinals", mlbID: 138, city: "St. Louis", name: "Cardinals", abbreviation: "STL", division: "NL Central"),
        .init(id: "tampa-bay-rays", mlbID: 139, city: "Tampa Bay", name: "Rays", abbreviation: "TB", division: "AL East"),
        .init(id: "texas-rangers", mlbID: 140, city: "Texas", name: "Rangers", abbreviation: "TEX", division: "AL West"),
        .init(id: "toronto-blue-jays", mlbID: 141, city: "Toronto", name: "Blue Jays", abbreviation: "TOR", division: "AL East"),
        .init(id: "washington-nationals", mlbID: 120, city: "Washington", name: "Nationals", abbreviation: "WSH", division: "NL East"),
    ]

    static func choice(id: String?) -> BaseballTeamChoice? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }
}

struct BaseballPlayerChoice: Equatable, Identifiable, Sendable {
    let id: Int
    let fullName: String
    let position: String
    let jerseyNumber: String?
}

protocol BaseballRosterProviding: Sendable {
    func roster(for team: BaseballTeamChoice) async throws
        -> [BaseballPlayerChoice]
}

enum BaseballRosterError: LocalizedError {
    case invalidResponse
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "MLB returned an invalid roster response."
        case .unavailable:
            "The roster is unavailable right now."
        }
    }
}

struct MLBStatsRosterProvider: BaseballRosterProviding {
    func roster(
        for team: BaseballTeamChoice
    ) async throws -> [BaseballPlayerChoice] {
        guard let url = URL(
            string: "https://statsapi.mlb.com/api/v1/teams/\(team.mlbID)/roster?rosterType=active"
        ) else {
            throw BaseballRosterError.invalidResponse
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw BaseballRosterError.invalidResponse
        }

        let payload = try JSONDecoder().decode(MLBRosterPayload.self, from: data)
        let players = payload.roster.map {
            BaseballPlayerChoice(
                id: $0.person.id,
                fullName: $0.person.fullName,
                position: $0.position.name,
                jerseyNumber: $0.jerseyNumber
            )
        }
        guard !players.isEmpty else {
            throw BaseballRosterError.unavailable
        }
        return players
    }
}

struct PrototypeBaseballRosterProvider: BaseballRosterProviding {
    static let rockies = [
        BaseballPlayerChoice(
            id: 696100,
            fullName: "Hunter Goodman",
            position: "Catcher",
            jerseyNumber: "15"
        ),
        BaseballPlayerChoice(
            id: -2,
            fullName: "Jordan Beck",
            position: "Outfielder",
            jerseyNumber: nil
        ),
        BaseballPlayerChoice(
            id: -3,
            fullName: "Brenton Doyle",
            position: "Outfielder",
            jerseyNumber: nil
        ),
        BaseballPlayerChoice(
            id: -4,
            fullName: "Ezequiel Tovar",
            position: "Shortstop",
            jerseyNumber: nil
        ),
        BaseballPlayerChoice(
            id: -5,
            fullName: "Kyle Freeland",
            position: "Pitcher",
            jerseyNumber: nil
        ),
    ]

    func roster(
        for team: BaseballTeamChoice
    ) async throws -> [BaseballPlayerChoice] {
        guard team.id == BaseballTeamChoice.coloradoRockies.id else {
            throw BaseballRosterError.unavailable
        }
        return Self.rockies
    }
}

struct AdaptiveBaseballRosterProvider: BaseballRosterProviding {
    private let live = MLBStatsRosterProvider()
    private let fallback = PrototypeBaseballRosterProvider()

    func roster(
        for team: BaseballTeamChoice
    ) async throws -> [BaseballPlayerChoice] {
        do {
            return try await live.roster(for: team)
        } catch {
            return try await fallback.roster(for: team)
        }
    }
}

private struct MLBRosterPayload: Decodable {
    let roster: [Entry]

    struct Entry: Decodable {
        let person: Person
        let jerseyNumber: String?
        let position: Position
    }

    struct Person: Decodable {
        let id: Int
        let fullName: String
    }

    struct Position: Decodable {
        let name: String
    }
}

@MainActor
@Observable
final class BaseballOnboardingState {
    static let signedInKey = "baseball.demoSignedIn"
    static let selectedTeamKey = "baseball.selectedTeam"
    static let selectedPlayerIDKey = "baseball.selectedPlayerID"
    static let selectedPlayerNameKey = "baseball.selectedPlayerName"
    static let selectedPlayerPositionKey = "baseball.selectedPlayerPosition"
    static let selectedPlayerNumberKey = "baseball.selectedPlayerNumber"
    static let completionVersionKey = "baseball.onboardingVersion"
    static let currentVersion = 2

    private(set) var isSignedIn: Bool
    private(set) var selectedTeamID: String?
    private(set) var selectedPlayer: BaseballPlayerChoice?
    private(set) var hasCompletedOnboarding: Bool
    private(set) var roster: [BaseballPlayerChoice] = []
    private(set) var isLoadingRoster = false
    private(set) var rosterError: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let rosterProvider: any BaseballRosterProviding
    @ObservationIgnored private var loadedRosterTeamID: String?

    init(
        defaults: UserDefaults = .standard,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        rosterProvider: (any BaseballRosterProviding)? = nil
    ) {
        self.defaults = defaults
        let usesFixtureRoster = arguments.contains("--baseball-ui-testing")
            || arguments.contains("--baseball-onboarding-ui-testing")
        self.rosterProvider = rosterProvider
            ?? (usesFixtureRoster
                ? PrototypeBaseballRosterProvider()
                : AdaptiveBaseballRosterProvider())

        if arguments.contains("--baseball-onboarding-ui-testing") {
            Self.clearPersonalization(in: defaults)
            isSignedIn = true
            selectedTeamID = nil
            selectedPlayer = nil
            hasCompletedOnboarding = false
        } else if arguments.contains("--baseball-signed-out-ui-testing") {
            isSignedIn = false
            selectedTeamID = BaseballTeamChoice.coloradoRockies.id
            selectedPlayer = Self.hunterGoodman
            hasCompletedOnboarding = true
        } else if arguments.contains("--baseball-ui-testing") {
            isSignedIn = true
            selectedTeamID = BaseballTeamChoice.coloradoRockies.id
            selectedPlayer = Self.hunterGoodman
            hasCompletedOnboarding = true
        } else {
            let storedTeamID = defaults.string(forKey: Self.selectedTeamKey)
            let storedPlayer = Self.storedPlayer(in: defaults)
            let storedVersion = defaults.integer(
                forKey: Self.completionVersionKey
            )
            let storedSignIn = defaults.object(forKey: Self.signedInKey)
                as? Bool

            selectedTeamID = storedTeamID
            selectedPlayer = storedPlayer
            isSignedIn = storedSignIn ?? (storedTeamID != nil)
            hasCompletedOnboarding =
                BaseballTeamChoice.choice(id: storedTeamID) != nil
                && storedPlayer != nil
                && storedVersion >= Self.currentVersion
        }
    }

    var selectedTeam: BaseballTeamChoice? {
        BaseballTeamChoice.choice(id: selectedTeamID)
    }

    var profileSnapshot: BaseballFanProfileSnapshot {
        let base = MockMichaelProfile.value
        let team = selectedTeam?.fullName ?? base.favoriteTeam
        let players = selectedPlayer.map { [$0.fullName] } ?? []
        return BaseballFanProfileSnapshot(
            id: base.id,
            name: base.name,
            favoriteTeam: team,
            favoritePlayers: players,
            rivalTeams: selectedTeamID == BaseballTeamChoice.coloradoRockies.id
                ? base.rivalTeams
                : [],
            interests: base.interests,
            stadiumVisits: base.stadiumVisits,
            frequentSearchThemes: base.frequentSearchThemes
        )
    }

    func setSignedIn(_ signedIn: Bool) {
        isSignedIn = signedIn
        defaults.set(signedIn, forKey: Self.signedInKey)
    }

    func selectTeam(_ team: BaseballTeamChoice) {
        if selectedTeamID != team.id {
            selectedPlayer = nil
            roster = []
            loadedRosterTeamID = nil
            rosterError = nil
            Self.clearStoredPlayer(in: defaults)
        }
        selectedTeamID = team.id
        defaults.set(team.id, forKey: Self.selectedTeamKey)
        hasCompletedOnboarding = false
        defaults.removeObject(forKey: Self.completionVersionKey)
    }

    func selectPlayer(_ player: BaseballPlayerChoice) {
        selectedPlayer = player
        defaults.set(player.id, forKey: Self.selectedPlayerIDKey)
        defaults.set(player.fullName, forKey: Self.selectedPlayerNameKey)
        defaults.set(player.position, forKey: Self.selectedPlayerPositionKey)
        defaults.set(player.jerseyNumber, forKey: Self.selectedPlayerNumberKey)
    }

    func loadRoster(force: Bool = false) async {
        guard let team = selectedTeam else {
            roster = []
            rosterError = nil
            return
        }
        if !force,
           loadedRosterTeamID == team.id,
           !roster.isEmpty {
            return
        }

        isLoadingRoster = true
        rosterError = nil
        defer { isLoadingRoster = false }

        do {
            let loaded = try await rosterProvider.roster(for: team)
            roster = loaded.sorted { lhs, rhs in
                if lhs.fullName == "Hunter Goodman" { return true }
                if rhs.fullName == "Hunter Goodman" { return false }
                return lhs.fullName.localizedCaseInsensitiveCompare(
                    rhs.fullName
                ) == .orderedAscending
            }
            loadedRosterTeamID = team.id
        } catch {
            roster = []
            loadedRosterTeamID = nil
            rosterError = error.localizedDescription
        }
    }

    @discardableResult
    func complete() -> Bool {
        guard selectedTeam != nil, selectedPlayer != nil else { return false }
        defaults.set(true, forKey: Self.signedInKey)
        defaults.set(Self.currentVersion, forKey: Self.completionVersionKey)
        isSignedIn = true
        hasCompletedOnboarding = true
        return true
    }

    func restartPersonalization() {
        Self.clearPersonalization(in: defaults)
        selectedTeamID = nil
        selectedPlayer = nil
        hasCompletedOnboarding = false
        roster = []
        loadedRosterTeamID = nil
        rosterError = nil
    }

    private static var hunterGoodman: BaseballPlayerChoice {
        PrototypeBaseballRosterProvider.rockies[0]
    }

    private static func storedPlayer(
        in defaults: UserDefaults
    ) -> BaseballPlayerChoice? {
        let id = defaults.integer(forKey: selectedPlayerIDKey)
        guard id != 0,
              let name = defaults.string(forKey: selectedPlayerNameKey),
              let position = defaults.string(
                forKey: selectedPlayerPositionKey
              ) else {
            return nil
        }
        return BaseballPlayerChoice(
            id: id,
            fullName: name,
            position: position,
            jerseyNumber: defaults.string(forKey: selectedPlayerNumberKey)
        )
    }

    private static func clearStoredPlayer(in defaults: UserDefaults) {
        defaults.removeObject(forKey: selectedPlayerIDKey)
        defaults.removeObject(forKey: selectedPlayerNameKey)
        defaults.removeObject(forKey: selectedPlayerPositionKey)
        defaults.removeObject(forKey: selectedPlayerNumberKey)
    }

    private static func clearPersonalization(in defaults: UserDefaults) {
        defaults.removeObject(forKey: selectedTeamKey)
        clearStoredPlayer(in: defaults)
        defaults.removeObject(forKey: completionVersionKey)
    }
}
