import Foundation

protocol BaseballHostEditorializing: Sendable {
    var providerName: String { get }

    func editorial(
        for plan: BaseballSearchPlan,
        snapshot: BaseballDataSnapshot,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballHostEditorial
}

struct DeterministicBaseballHostEditor: BaseballHostEditorializing {
    let providerName = "Deterministic baseball editor"

    func editorial(
        for plan: BaseballSearchPlan,
        snapshot: BaseballDataSnapshot,
        profile: BaseballFanProfileSnapshot
    ) async throws -> BaseballHostEditorial {
        let groundedFactIDs = Array(snapshot.supportingFacts.prefix(3).map(\.id))
        let subject = plan.query.entities.first?.canonicalName
        let line: String

        switch plan.query.intent {
        case .entityLookup:
            line = "\(subject ?? "This player") gets the spotlight. Start with the signal, then decide what deserves your time."
        case .teamLookup:
            line = "\(subject ?? profile.favoriteTeam) is on the board. Schedule, stakes, and the part you should care about—ready."
        case .gamesTonight:
            line = "Tonight’s slate is sorted. I moved the games that matter to you to the front."
        case .playerRecommendation:
            line = "I found your next player to watch. The interesting part is why the moment fits your baseball."
        case .playerComparison:
            line = "Good comparison. Skip the stat pile—start with where their games actually separate."
        case .availabilityExplanation:
            line = "There is context behind the absence. Facts first; speculation stays clearly labeled."
        case .missedGamesRecap:
            line = "You missed baseball, not the story. Here are the moments that changed what comes next."
        case .standingsImpact:
            line = "Now the standings get personal. One result can change which games deserve your attention."
        case .personalAttendanceHistory:
            line = "I found your ballpark trail. This is your baseball history, not a generic archive."
        case .watchNext:
            line = "Your next watch is ready. It earned the recommendation with relevance, not popularity."
        case .unknown:
            line = "Give me a player, team, game, comparison, or playoff question. I’ll build the experience."
        }

        let why: String
        if plan.query.intent == .standingsImpact || profile.interests.contains(.playoffRaces) {
            why = "\(profile.name) follows playoff implications, so this view leads with standings consequences instead of a generic recap."
        } else if plan.query.intent == .personalAttendanceHistory {
            why = "This connects \(profile.name)’s \(profile.favoriteTeam) fandom to the ballparks already in the profile."
        } else if plan.query.intent == .playerRecommendation || profile.interests.contains(.emergingPlayers) {
            why = "\(profile.name) follows emerging players and great stories, so this emphasizes trajectory and watchability."
        } else {
            why = "This is ordered around \(profile.name)’s \(profile.favoriteTeam) fandom and stated baseball interests."
        }

        return BaseballHostEditorial(
            reaction: BaseballHostReaction(
                id: "reaction-\(plan.query.intent.rawValue)",
                line: line,
                kind: .opinion,
                providerName: providerName,
                groundedFactIDs: groundedFactIDs,
                behavior: plan.hostBehavior
            ),
            whyThisMatters: BaseballWhyThisMattersCard(
                id: "why-\(plan.query.intent.rawValue)",
                title: "Why this matters to \(profile.name)",
                explanation: why,
                kind: .opinion,
                groundedFactIDs: groundedFactIDs
            )
        )
    }
}
