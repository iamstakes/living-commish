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
        let reactionKind: BaseballClaimKind

        switch plan.query.intent {
        case .favoriteTeam:
            line = "Your favorite team is the \(profile.favoriteTeam)."
            reactionKind = .fact
        case .favoritePlayer:
            if let favoritePlayer = profile.favoritePlayers.first {
                line = "Your favorite player is \(favoritePlayer)."
            } else {
                line = "You have not chosen a favorite player yet."
            }
            reactionKind = .fact
        case .entityLookup:
            line = "\(subject ?? "This player") gets the spotlight. Start with the signal, then decide what deserves your time."
            reactionKind = .opinion
        case .teamLookup:
            line = "\(subject ?? profile.favoriteTeam) is on the board. Schedule, stakes, and the part you should care about—ready."
            reactionKind = .opinion
        case .gamesTonight:
            line = "Tonight’s slate is sorted. I moved the games that matter to you to the front."
            reactionKind = .opinion
        case .playerRecommendation:
            line = "I found your next player to watch. The interesting part is why the moment fits your baseball."
            reactionKind = .opinion
        case .playerComparison:
            line = "Good comparison. Skip the stat pile—start with where their games actually separate."
            reactionKind = .opinion
        case .availabilityExplanation:
            line = "There is context behind the absence. Facts first; speculation stays clearly labeled."
            reactionKind = .opinion
        case .missedGamesRecap:
            line = "You missed baseball, not the story. Here are the moments that changed what comes next."
            reactionKind = .opinion
        case .standingsImpact:
            line = "Now the standings get personal. One result can change which games deserve your attention."
            reactionKind = .opinion
        case .personalAttendanceHistory:
            line = "I found your ballpark trail. This is your baseball history, not a generic archive."
            reactionKind = .opinion
        case .watchNext:
            line = "Your next watch is ready. It earned the recommendation with relevance, not popularity."
            reactionKind = .opinion
        case .unknown:
            throw BaseballSearchArchitectureError.needsRefinement(
                plan.query.ambiguity
                    ?? "Try a player, team, game, comparison, or playoff question."
            )
        }

        let why: String
        let whyKind: BaseballClaimKind
        if plan.query.intent == .favoriteTeam || plan.query.intent == .favoritePlayer {
            why = "This answer comes from \(profile.name)’s prototype fan profile."
            whyKind = .fact
        } else if plan.query.intent == .standingsImpact || profile.interests.contains(.playoffRaces) {
            why = "\(profile.name) follows playoff implications, so this view leads with standings consequences instead of a generic recap."
            whyKind = .opinion
        } else if plan.query.intent == .personalAttendanceHistory {
            why = "This connects \(profile.name)’s \(profile.favoriteTeam) fandom to the ballparks already in the profile."
            whyKind = .opinion
        } else if plan.query.intent == .playerRecommendation || profile.interests.contains(.emergingPlayers) {
            why = "\(profile.name) follows emerging players and great stories, so this emphasizes trajectory and watchability."
            whyKind = .opinion
        } else {
            why = "This is ordered around \(profile.name)’s \(profile.favoriteTeam) fandom and stated baseball interests."
            whyKind = .opinion
        }

        return BaseballHostEditorial(
            reaction: BaseballHostReaction(
                id: "reaction-\(plan.query.intent.rawValue)",
                line: line,
                kind: reactionKind,
                providerName: providerName,
                groundedFactIDs: groundedFactIDs,
                behavior: plan.hostBehavior
            ),
            whyThisMatters: BaseballWhyThisMattersCard(
                id: "why-\(plan.query.intent.rawValue)",
                title: "Why this matters to \(profile.name)",
                explanation: why,
                kind: whyKind,
                groundedFactIDs: groundedFactIDs
            )
        )
    }
}
