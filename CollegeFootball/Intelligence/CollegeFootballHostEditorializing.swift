import Foundation

protocol CollegeFootballHostEditorializing: Sendable {
    var providerName: String { get }

    func editorial(
        for plan: CollegeFootballSearchPlan,
        snapshot: CollegeFootballDataSnapshot,
        profile: CollegeFootballFanProfileSnapshot
    ) async throws -> CollegeFootballHostEditorial
}

struct DeterministicCollegeFootballHostEditor: CollegeFootballHostEditorializing {
    let providerName = "Deterministic college football editor"

    func editorial(
        for plan: CollegeFootballSearchPlan,
        snapshot: CollegeFootballDataSnapshot,
        profile: CollegeFootballFanProfileSnapshot
    ) async throws -> CollegeFootballHostEditorial {
        let groundedFactIDs = Array(snapshot.supportingFacts.prefix(3).map(\.id))
        let subject = plan.query.entities.first?.canonicalName
        let line: String
        let reactionKind: CollegeFootballClaimKind

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
            line = entityLookupLine(subject: subject, snapshot: snapshot)
            reactionKind = .opinion
        case .teamLookup:
            line = "\(subject ?? profile.favoriteTeam) is on the board. Schedule, stakes, and the part you should care about—ready."
            reactionKind = .opinion
        case .gamesTonight:
            line = "The Saturday slate is sorted. I moved the games that matter to you to the front."
            reactionKind = .opinion
        case .playerRecommendation:
            line = "I found your next player to watch. The interesting part is why the moment fits your college football fandom."
            reactionKind = .opinion
        case .playerComparison:
            line = "Good comparison. Skip the stat pile—start with where their games actually separate."
            reactionKind = .opinion
        case .availabilityExplanation:
            line = "There is context behind the absence. Facts first; speculation stays clearly labeled."
            reactionKind = .opinion
        case .missedGamesRecap:
            line = "You missed the games, not the story. Here are the moments that changed what comes next."
            reactionKind = .opinion
        case .standingsImpact:
            line = "Now the standings get personal. One result can change which games deserve your attention."
            reactionKind = .opinion
        case .personalAttendanceHistory:
            line = "I found your stadium trail. This is your college football history, not a generic archive."
            reactionKind = .opinion
        case .watchNext:
            line = "Your next watch is ready. It earned the recommendation with relevance, not popularity."
            reactionKind = .opinion
        case .unknown:
            throw CollegeFootballSearchArchitectureError.needsRefinement(
                plan.query.ambiguity
                    ?? "Try a player, team, game, comparison, or playoff question."
            )
        }

        let why: String
        let whyKind: CollegeFootballClaimKind
        if plan.query.intent == .favoriteTeam || plan.query.intent == .favoritePlayer {
            why = "This answer comes from \(profile.name)’s prototype fan profile."
            whyKind = .fact
        } else if plan.query.intent == .entityLookup,
                  let player = snapshot.modules.compactMap(\.player).first {
            why = "\(player.name) was your explicit subject, so his role and the available player-specific evidence lead this result."
            whyKind = .opinion
        } else if plan.query.intent == .standingsImpact {
            why = "\(profile.name) follows playoff implications, so this view leads with standings consequences instead of a generic recap."
            whyKind = .opinion
        } else if plan.query.intent == .personalAttendanceHistory {
            why = "This connects \(profile.name)’s \(profile.favoriteTeam) fandom to the stadiums already in the profile."
            whyKind = .opinion
        } else if plan.query.intent == .playerRecommendation {
            why = "\(profile.name) follows emerging players and great stories, so this emphasizes trajectory and watchability."
            whyKind = .opinion
        } else {
            why = "This is ordered around \(profile.name)’s \(profile.favoriteTeam) fandom and stated college football interests."
            whyKind = .opinion
        }

        return CollegeFootballHostEditorial(
            reaction: CollegeFootballHostReaction(
                id: "reaction-\(plan.query.intent.rawValue)",
                line: line,
                kind: reactionKind,
                providerName: providerName,
                groundedFactIDs: groundedFactIDs,
                behavior: plan.hostBehavior
            ),
            whyThisMatters: CollegeFootballWhyThisMattersCard(
                id: "why-\(plan.query.intent.rawValue)",
                title: "Why this matters to \(profile.name)",
                explanation: why,
                kind: whyKind,
                groundedFactIDs: groundedFactIDs
            )
        )
    }

    private func entityLookupLine(
        subject: String?,
        snapshot: CollegeFootballDataSnapshot
    ) -> String {
        guard let player = snapshot.modules.compactMap(\.player).first else {
            return "I found \(subject ?? "the player"), but there is no grounded player profile to interpret yet."
        }

        if player.id == "travis-hunter",
           snapshot.modules.contains(where: \.isPerformance) {
            return "Travis Hunter’s story starts with the workload: elite production at receiver and corner in the same Heisman season."
        }

        if player.id == "shedeur-sanders" {
            return "Shedeur Sanders is the quarterback at the center of Colorado’s modern offensive story."
        }

        if player.id == "ashton-jeanty" {
            return "Ashton Jeanty supplies the cleanest contrast to Hunter: historic rushing production against unprecedented two-way value."
        }

        if player.id == "charles-woodson" {
            return "Charles Woodson is the historical reference point: a defensive star whose versatility carried him to the Heisman."
        }

        return "\(player.name) is a \(player.position.lowercased()) for the \(player.teamName). The result below stays on the evidence available for him."
    }
}

private extension CollegeFootballResultModule {
    var player: CollegeFootballPlayerCard? {
        if case .player(let player) = self { return player }
        return nil
    }

    var isPerformance: Bool {
        if case .performance = self { return true }
        return false
    }
}
