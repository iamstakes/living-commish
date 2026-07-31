import Foundation
import Observation

struct CollegeFootballTeamChoice: Equatable, Identifiable, Sendable {
    let id: String
    let espnID: Int
    let city: String
    let name: String
    let abbreviation: String
    let division: String

    var fullName: String {
        city.isEmpty ? name : "\(city) \(name)"
    }

    static let coloradoBuffaloes = CollegeFootballTeamChoice(
        id: "colorado-buffaloes",
        espnID: 38,
        city: "Colorado",
        name: "Buffaloes",
        abbreviation: "COLO",
        division: "Big 12"
    )

    static let all: [CollegeFootballTeamChoice] = [
        .init(id: "alabama", espnID: 333, city: "Alabama", name: "Crimson Tide", abbreviation: "ALA", division: "SEC"),
        .init(id: "arizona-state", espnID: 9, city: "Arizona State", name: "Sun Devils", abbreviation: "ASU", division: "Big 12"),
        .init(id: "auburn", espnID: 2, city: "Auburn", name: "Tigers", abbreviation: "AUB", division: "SEC"),
        .init(id: "boise-state", espnID: 68, city: "Boise State", name: "Broncos", abbreviation: "BOIS", division: "Pac-12"),
        .init(id: "clemson", espnID: 228, city: "Clemson", name: "Tigers", abbreviation: "CLEM", division: "ACC"),
        .coloradoBuffaloes,
        .init(id: "florida", espnID: 57, city: "Florida", name: "Gators", abbreviation: "FLA", division: "SEC"),
        .init(id: "florida-state", espnID: 52, city: "Florida State", name: "Seminoles", abbreviation: "FSU", division: "ACC"),
        .init(id: "georgia", espnID: 61, city: "Georgia", name: "Bulldogs", abbreviation: "UGA", division: "SEC"),
        .init(id: "kansas-state", espnID: 2306, city: "Kansas State", name: "Wildcats", abbreviation: "KSU", division: "Big 12"),
        .init(id: "lsu", espnID: 99, city: "LSU", name: "Tigers", abbreviation: "LSU", division: "SEC"),
        .init(id: "miami", espnID: 2390, city: "Miami", name: "Hurricanes", abbreviation: "MIA", division: "ACC"),
        .init(id: "michigan", espnID: 130, city: "Michigan", name: "Wolverines", abbreviation: "MICH", division: "Big Ten"),
        .init(id: "michigan-state", espnID: 127, city: "Michigan State", name: "Spartans", abbreviation: "MSU", division: "Big Ten"),
        .init(id: "nebraska", espnID: 158, city: "Nebraska", name: "Cornhuskers", abbreviation: "NEB", division: "Big Ten"),
        .init(id: "notre-dame", espnID: 87, city: "Notre Dame", name: "Fighting Irish", abbreviation: "ND", division: "Independent"),
        .init(id: "ohio-state", espnID: 194, city: "Ohio State", name: "Buckeyes", abbreviation: "OSU", division: "Big Ten"),
        .init(id: "oklahoma", espnID: 201, city: "Oklahoma", name: "Sooners", abbreviation: "OU", division: "SEC"),
        .init(id: "oregon", espnID: 2483, city: "Oregon", name: "Ducks", abbreviation: "ORE", division: "Big Ten"),
        .init(id: "penn-state", espnID: 213, city: "Penn State", name: "Nittany Lions", abbreviation: "PSU", division: "Big Ten"),
        .init(id: "south-carolina", espnID: 2579, city: "South Carolina", name: "Gamecocks", abbreviation: "SC", division: "SEC"),
        .init(id: "tennessee", espnID: 2633, city: "Tennessee", name: "Volunteers", abbreviation: "TENN", division: "SEC"),
        .init(id: "texas", espnID: 251, city: "Texas", name: "Longhorns", abbreviation: "TEX", division: "SEC"),
        .init(id: "texas-am", espnID: 245, city: "Texas A&M", name: "Aggies", abbreviation: "TA&M", division: "SEC"),
        .init(id: "ucla", espnID: 26, city: "UCLA", name: "Bruins", abbreviation: "UCLA", division: "Big Ten"),
        .init(id: "usc", espnID: 30, city: "USC", name: "Trojans", abbreviation: "USC", division: "Big Ten"),
        .init(id: "utah", espnID: 254, city: "Utah", name: "Utes", abbreviation: "UTAH", division: "Big 12"),
        .init(id: "washington", espnID: 264, city: "Washington", name: "Huskies", abbreviation: "WASH", division: "Big Ten"),
        .init(id: "west-virginia", espnID: 277, city: "West Virginia", name: "Mountaineers", abbreviation: "WVU", division: "Big 12"),
        .init(id: "wisconsin", espnID: 275, city: "Wisconsin", name: "Badgers", abbreviation: "WIS", division: "Big Ten"),
    ]

    static func choice(id: String?) -> CollegeFootballTeamChoice? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }
}

struct CollegeFootballPlayerChoice: Equatable, Identifiable, Sendable {
    let id: Int
    let fullName: String
    let position: String
    let jerseyNumber: String?
}

protocol CollegeFootballRosterProviding: Sendable {
    func roster(for team: CollegeFootballTeamChoice) async throws
        -> [CollegeFootballPlayerChoice]
}

enum CollegeFootballRosterError: LocalizedError {
    case invalidResponse
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "FBS returned an invalid roster response."
        case .unavailable:
            "The roster is unavailable right now."
        }
    }
}

struct ESPNCollegeFootballRosterProvider: CollegeFootballRosterProviding {
    func roster(
        for team: CollegeFootballTeamChoice
    ) async throws -> [CollegeFootballPlayerChoice] {
        guard let url = URL(
            string: "https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams/\(team.espnID)/roster"
        ) else {
            throw CollegeFootballRosterError.invalidResponse
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw CollegeFootballRosterError.invalidResponse
        }

        let payload = try JSONDecoder().decode(ESPNRosterPayload.self, from: data)
        let entries = payload.athletes.flatMap { $0.items }
        let players: [CollegeFootballPlayerChoice] = entries.compactMap { player in
            guard let id = Int(player.id) else { return nil }
            return CollegeFootballPlayerChoice(
                id: id,
                fullName: player.fullName,
                position: player.position.name,
                jerseyNumber: player.jersey
            )
        }
        guard !players.isEmpty else {
            throw CollegeFootballRosterError.unavailable
        }
        return players
    }
}

struct PrototypeCollegeFootballRosterProvider: CollegeFootballRosterProviding {
    static let buffaloes = [
        CollegeFootballPlayerChoice(
            id: 4430878,
            fullName: "Travis Hunter",
            position: "Cornerback / Wide Receiver",
            jerseyNumber: "12"
        ),
        CollegeFootballPlayerChoice(
            id: -2,
            fullName: "Shedeur Sanders",
            position: "Quarterback",
            jerseyNumber: "2"
        ),
        CollegeFootballPlayerChoice(
            id: -3,
            fullName: "Rashaan Salaam",
            position: "Running Back",
            jerseyNumber: "19"
        ),
        CollegeFootballPlayerChoice(
            id: -4,
            fullName: "Kordell Stewart",
            position: "Quarterback",
            jerseyNumber: "10"
        ),
        CollegeFootballPlayerChoice(
            id: -5,
            fullName: "Michael Westbrook",
            position: "Wide Receiver",
            jerseyNumber: "81"
        ),
    ]

    func roster(
        for team: CollegeFootballTeamChoice
    ) async throws -> [CollegeFootballPlayerChoice] {
        guard team.id == CollegeFootballTeamChoice.coloradoBuffaloes.id else {
            throw CollegeFootballRosterError.unavailable
        }
        return Self.buffaloes
    }
}

struct AdaptiveCollegeFootballRosterProvider: CollegeFootballRosterProviding {
    private let live = ESPNCollegeFootballRosterProvider()
    private let fallback = PrototypeCollegeFootballRosterProvider()

    func roster(
        for team: CollegeFootballTeamChoice
    ) async throws -> [CollegeFootballPlayerChoice] {
        do {
            let liveRoster = try await live.roster(for: team)
            guard team.id == CollegeFootballTeamChoice.coloradoBuffaloes.id else {
                return liveRoster
            }
            let featured = try await fallback.roster(for: team)
            let liveIDs = Set(liveRoster.map(\.id))
            return featured.filter { !liveIDs.contains($0.id) } + liveRoster
        } catch {
            return try await fallback.roster(for: team)
        }
    }
}

private struct ESPNRosterPayload: Decodable {
    let athletes: [Group]

    struct Group: Decodable {
        let items: [Entry]
    }

    struct Entry: Decodable {
        let id: String
        let fullName: String
        let jersey: String?
        let position: Position
    }

    struct Position: Decodable {
        let name: String
    }
}

@MainActor
@Observable
final class CollegeFootballOnboardingState {
    enum Step: Equatable {
        case team
        case player
        case ready
    }

    static let signedInKey = "collegeFootball.demoSignedIn"
    static let selectedTeamKey = "collegeFootball.selectedTeam"
    static let selectedPlayerIDKey = "collegeFootball.selectedPlayerID"
    static let selectedPlayerNameKey = "collegeFootball.selectedPlayerName"
    static let selectedPlayerPositionKey = "collegeFootball.selectedPlayerPosition"
    static let selectedPlayerNumberKey = "collegeFootball.selectedPlayerNumber"
    static let completionVersionKey = "collegeFootball.onboardingVersion"
    static let currentVersion = 2

    private(set) var isSignedIn: Bool
    private(set) var selectedTeamID: String?
    private(set) var selectedPlayer: CollegeFootballPlayerChoice?
    private(set) var hasCompletedOnboarding: Bool
    private(set) var step: Step = .team
    private(set) var roster: [CollegeFootballPlayerChoice] = []
    private(set) var isLoadingRoster = false
    private(set) var rosterError: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let rosterProvider: any CollegeFootballRosterProviding
    @ObservationIgnored private var loadedRosterTeamID: String?

    init(
        defaults: UserDefaults = .standard,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        rosterProvider: (any CollegeFootballRosterProviding)? = nil
    ) {
        self.defaults = defaults
        let usesFixtureRoster = arguments.contains("--collegeFootball-ui-testing")
            || arguments.contains("--collegeFootball-onboarding-ui-testing")
        self.rosterProvider = rosterProvider
            ?? (usesFixtureRoster
                ? PrototypeCollegeFootballRosterProvider()
                : AdaptiveCollegeFootballRosterProvider())

        if arguments.contains("--collegeFootball-onboarding-ui-testing") {
            Self.clearPersonalization(in: defaults)
            isSignedIn = false
            selectedTeamID = nil
            selectedPlayer = nil
            hasCompletedOnboarding = false
        } else if arguments.contains("--collegeFootball-ui-testing") {
            isSignedIn = true
            selectedTeamID = CollegeFootballTeamChoice.coloradoBuffaloes.id
            selectedPlayer = Self.travisHunter
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
            let storedOnboardingIsComplete =
                CollegeFootballTeamChoice.choice(id: storedTeamID) != nil
                && storedPlayer != nil
                && storedVersion >= Self.currentVersion
            hasCompletedOnboarding = storedOnboardingIsComplete
            isSignedIn =
                (storedSignIn ?? (storedTeamID != nil))
                && storedOnboardingIsComplete
        }

        step = isSignedIn
            ? Self.resolvedStep(
                teamID: selectedTeamID,
                player: selectedPlayer
            )
            : .team
    }

    var selectedTeam: CollegeFootballTeamChoice? {
        CollegeFootballTeamChoice.choice(id: selectedTeamID)
    }

    var isPersonalizedExperienceActive: Bool {
        isSignedIn
            && hasCompletedOnboarding
            && selectedTeam != nil
            && selectedPlayer != nil
    }

    var profileSnapshot: CollegeFootballFanProfileSnapshot {
        let base = MockMichaelProfile.value
        let team = selectedTeam?.fullName ?? "No favorite team selected"
        let players = selectedPlayer.map { [$0.fullName] } ?? []
        return CollegeFootballFanProfileSnapshot(
            id: base.id,
            name: isSignedIn ? base.name : "College Football Fan",
            favoriteTeam: team,
            favoritePlayers: players,
            rivalTeams: selectedTeamID == CollegeFootballTeamChoice.coloradoBuffaloes.id
                ? base.rivalTeams
                : [],
            interests: base.interests,
            stadiumVisits: base.stadiumVisits,
            frequentSearchThemes: base.frequentSearchThemes
        )
    }

    func simulatePersonalizedExperience(_ isActive: Bool) {
        restartPersonalization()
        guard isActive else { return }

        selectTeam(.coloradoBuffaloes)
        selectPlayer(Self.travisHunter)
        _ = complete()
    }

    func selectTeam(_ team: CollegeFootballTeamChoice) {
        if selectedTeamID != team.id {
            selectedPlayer = nil
            roster = []
            loadedRosterTeamID = nil
            rosterError = nil
            Self.clearStoredPlayer(in: defaults)
        }
        selectedTeamID = team.id
        step = .player
        defaults.set(team.id, forKey: Self.selectedTeamKey)
        hasCompletedOnboarding = false
        defaults.removeObject(forKey: Self.completionVersionKey)
    }

    func selectPlayer(_ player: CollegeFootballPlayerChoice) {
        selectedPlayer = player
        step = .ready
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
                if lhs.fullName == "Travis Hunter" { return true }
                if rhs.fullName == "Travis Hunter" { return false }
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
        isSignedIn = false
        selectedTeamID = nil
        selectedPlayer = nil
        hasCompletedOnboarding = false
        step = .team
        roster = []
        loadedRosterTeamID = nil
        rosterError = nil
    }

    private static var travisHunter: CollegeFootballPlayerChoice {
        PrototypeCollegeFootballRosterProvider.buffaloes[0]
    }

    private static func resolvedStep(
        teamID: String?,
        player: CollegeFootballPlayerChoice?
    ) -> Step {
        guard CollegeFootballTeamChoice.choice(id: teamID) != nil else {
            return .team
        }
        return player == nil ? .player : .ready
    }

    private static func storedPlayer(
        in defaults: UserDefaults
    ) -> CollegeFootballPlayerChoice? {
        let id = defaults.integer(forKey: selectedPlayerIDKey)
        guard id != 0,
              let name = defaults.string(forKey: selectedPlayerNameKey),
              let position = defaults.string(
                forKey: selectedPlayerPositionKey
              ) else {
            return nil
        }
        return CollegeFootballPlayerChoice(
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
        defaults.removeObject(forKey: signedInKey)
        defaults.removeObject(forKey: selectedTeamKey)
        clearStoredPlayer(in: defaults)
        defaults.removeObject(forKey: completionVersionKey)
    }
}
