import Foundation

@MainActor
final class DeterministicCommishProvider: CommishIntelligenceProviding {
    let providerName = "Personalized local"
    let isAvailable = true
    let availabilityDescription = "Always available on device"
    private var lastLineByTopic: [ReactionTopic: String] = [:]

    func react(to event: FanEvent, brief: ReactionBrief) async throws -> CommishReaction {
        let options = responses(for: brief)
        let previous = lastLineByTopic[brief.topic]
        let line = options.first(where: { $0 != previous }) ?? options[0]
        lastLineByTopic[brief.topic] = line
        return CommishReaction(
            line: line,
            action: brief.desiredAction,
            emotion: brief.desiredEmotion,
            memoryDecision: .none,
            memoryValue: nil
        )
    }

    func resetSession() {
        lastLineByTopic.removeAll()
    }

    private func responses(for brief: ReactionBrief) -> [String] {
        switch brief.topic {
        case .attendance:
            if brief.signals.traditionName == "Whiteout", let favorite = brief.favoriteTeam {
                return [
                    "Whiteout confirmed. \(favorite) gets your full volume before kickoff even arrives.",
                    "You’re headed to the Whiteout. \(favorite) just gained one more voice in the storm.",
                ]
            }
            if let favorite = brief.favoriteTeam {
                return [
                    "\(favorite) game on the calendar. The Commish expects full volume.",
                    "Tickets secured. \(favorite) gets your energy before the opening whistle.",
                ]
            }
            return [
                "Game day is on the calendar. Bring the noise and leave your indoor voice home.",
                "Tickets secured. Anticipation is now officially part of the pregame report.",
            ]
        case .helmet:
            if let opponent = brief.opponent, let count = brief.opponentHelmetCount {
                return [
                    "\(count + 1) \(opponent) helmets? You’re not winning—you’re running an equipment amnesty.",
                    "\(opponent) just lost helmet number \(count + 1). Your trophy case needs a safety inspection.",
                ]
            }
            return [
                "Another helmet cracked. Somewhere, an equipment manager just felt a disturbance in the budget.",
                "That helmet had a family. Celebrate recklessly, but file the paperwork.",
            ]
        case .streakExtended:
            if let favorite = brief.favoriteTeam {
                return [
                    "The streak grows. \(favorite) fans now have documented proof that momentum enjoys your company.",
                    "\(favorite) confidence just gained another day and an extremely loud press conference.",
                ]
            }
            return [
                "The streak has stopped being a habit and started demanding its own documentary.",
                "Another day secured. Your calendar is becoming evidence.",
            ]
        case .streakLost:
            return [
                "Let it hurt for one possession—then build the next streak meaner.",
                "The number reset. Your standards didn’t. Back to work.",
            ]
        case .correct:
            return [
                "Correct. Somewhere, a replay official quietly deleted their draft apology.",
                "Clean call. No replay, no committee, no nervous explanation required.",
            ]
        case .incorrect:
            return [
                "Wrong call. The tape is cruel, but your comeback gets the next possession.",
                "That answer hit the upright. Breathe, reload, and make the next one undeniable.",
            ]
        case .challenge:
            return [
                "Challenge accepted. Bring receipts; confidence without film is just expensive noise.",
                "You called your shot. Now survive the replay booth.",
            ]
        case .explanation:
            if let favorite = brief.favoriteTeam, let rival = brief.rivalTeam {
                return [
                    "\(favorite) and \(rival) don’t play for points. They play for jurisdiction over the group chat.",
                    "Because \(favorite)–\(rival) survives the scoreboard. The winner controls every family dinner.",
                ]
            }
            return [
                "The stakes turn ordinary possessions into evidence. That’s why nobody watches this one calmly.",
                "History adds weight; rivalry adds witnesses. Suddenly every mistake has a long memory.",
            ]
        case .opinion:
            if let favorite = brief.favoriteTeam {
                return [
                    "\(favorite)’s culture matters when pressure rises: players trust their roles instead of chasing the moment.",
                    "A coach builds culture when \(favorite) stays connected under pressure instead of playing as eleven individuals.",
                ]
            }
            return [
                "Culture matters when pressure rises: players trust their roles instead of chasing the moment.",
                "A coach builds culture when the team stays connected under pressure instead of playing as eleven individuals.",
            ]
        case .greeting:
            return [
                "You’re back. Straighten the tie—the league has fresh chaos to process.",
                "Welcome in. The desk is messy, the takes are worse, and we’re exactly on schedule.",
            ]
        case .recruiting:
            return recruitingResponses(for: brief)
        case .transfer:
            return transferResponses(for: brief)
        case .injury:
            if let actor = brief.actor {
                return [
                    "\(actor) injury news lands hard. Rivalry pauses; nobody celebrates the medical tent.",
                    "That’s bigger than the scoreboard. Give \(actor) the shrug, the silence, and a healthy return.",
                ]
            }
            return [
                "Injury news changes the room. Rivalry can wait; health gets the entire spotlight.",
                "No punchline for the medical tent. The league office wants a full recovery.",
            ]
        case .ranking:
            return rankingResponses(for: brief)
        case .rivalryWin:
            if let favorite = brief.favoriteTeam, let rival = brief.rivalTeam {
                return [
                    "\(rival) handled. \(favorite)’s group chat is legally insufferable for the next 24 hours.",
                    "\(favorite) beat \(rival). Bragging rights renewed; humility has been placed on waivers.",
                ]
            }
            return [
                "Rival beaten. Bragging rights renewed; humility has been placed on waivers.",
                "The rivalry ledger is signed. Your group chat now has temporary diplomatic immunity.",
            ]
        case .dominantWin:
            if let winner = brief.actor, let loser = brief.target {
                return [
                    "\(winner) didn’t win. \(loser) got evicted from their own highlight reel.",
                    "\(loser) brought a game plan. \(winner) returned it marked insufficient.",
                ]
            }
            return [
                "That wasn’t a win. That was a hostile takeover with a scoreboard attached.",
                "The final whistle should have come with a witness-protection form.",
            ]
        case .dominantLoss:
            if let winner = brief.actor, let loser = brief.target {
                if let stakes = brief.stakes {
                    return [
                        "\(loser) reached \(stakes). \(winner) turned the moment into a public audit.",
                        "\(winner) made \(stakes) feel like \(loser)’s longest flight home.",
                    ]
                }
                return [
                    "\(winner) didn’t beat \(loser). They repossessed the highlight reel and changed the Wi-Fi password.",
                    "\(loser) showed up. \(winner) turned the scoreboard into a public audit.",
                ]
            }
            return [
                "That wasn’t a loss. That was emotional damage with official statistics.",
                "Some defeats hurt. That one changed the group-chat weather.",
            ]
        case .heartbreak:
            if let stakes = brief.stakes {
                return [
                    "A loss at \(stakes)? That one doesn’t sting—it moves in and starts paying rent.",
                    "Getting that close makes the silence louder. Let the shrug have its moment.",
                ]
            }
            return [
                "That ending leaves a bruise no box score can explain.",
                "So close is a cruel address. Stay there briefly, then move.",
            ]
        case .upset:
            if let winner = brief.actor {
                return [
                    "\(winner) just kicked the bracket door in and took the hinges as souvenirs.",
                    "The favorite brought expectations. \(winner) brought a crowbar.",
                ]
            }
            return [
                "The bracket just made a noise only broken furniture should make.",
                "That upset didn’t bust predictions—it repossessed them.",
            ]
        case .win:
            if let winner = brief.actor, let loser = brief.target {
                return [
                    "\(winner) owns the result. \(loser) owns a very long ride home.",
                    "\(winner) gets the headline; \(loser) gets film study and airplane mode.",
                ]
            }
            return [
                "That win comes with 24 hours of unbearable group-chat confidence. Spend it recklessly.",
                "Victory confirmed. Humility may report back to the roster tomorrow.",
            ]
        case .loss:
            if let loser = brief.target {
                return [
                    "\(loser) just donated an evening to the opponent’s group chat. Brutal.",
                    "That result belongs in the film room, behind a locked door.",
                ]
            }
            return [
                "That one leaves a bruise. No speech—just the shrug, then the next possession.",
                "The scoreboard was rude. Don’t let it write the sequel.",
            ]
        case .controversy:
            return [
                "The whistle spoke. Common sense immediately requested a trade.",
                "I’ve seen cleaner decisions made in a group chat at 2 a.m.",
            ]
        case .news, .unknown:
            return perspectiveAwareGeneralResponses(for: brief)
        }
    }

    private func recruitingResponses(for brief: ReactionBrief) -> [String] {
        let actor = brief.actor ?? brief.rivalTeam ?? "That program"
        if brief.relationship == .rival, let favorite = brief.favoriteTeam {
            return [
                "\(actor) added elite talent. \(favorite)’s margin for error just got smaller.",
                "\(actor) added another five-star. \(favorite) just got another reason to raise its standard.",
            ]
        }
        if brief.relationship == .favorite {
            return [
                "\(actor) signed a five-star. Someone alert the rankings before the confidence becomes structural.",
                "\(actor) landed another recruit. The future just walked in wearing expectations and excellent stars.",
            ]
        }
        return [
            "\(actor) landed a recruit. The depth chart just developed a new political party.",
            "Another commitment secured. Somewhere, a position coach is already rearranging the entire future.",
        ]
    }

    private func transferResponses(for brief: ReactionBrief) -> [String] {
        let actor = brief.actor ?? brief.rivalTeam ?? brief.favoriteTeam ?? "That program"
        if brief.relationship == .rival, let favorite = brief.favoriteTeam {
            return [
                "\(actor) worked the portal. \(favorite) just circled the matchup with considerably darker ink.",
                "The portal helped \(actor). \(favorite)’s revenge board has accepted the new filing.",
            ]
        }
        if brief.relationship == .favorite {
            return [
                "\(actor) found portal help. The depth chart just stood taller and started talking louder.",
                "That transfer changes the room. \(actor) now has options—and dangerous levels of confidence.",
            ]
        }
        return [
            "The portal moved again. Depth charts everywhere are pretending not to panic.",
            "New jersey, new politics. That locker room just received a very interesting plot twist.",
        ]
    }

    private func rankingResponses(for brief: ReactionBrief) -> [String] {
        let actor = brief.actor ?? brief.rivalTeam ?? brief.favoriteTeam ?? "That team"
        if brief.relationship == .rival, let favorite = brief.favoriteTeam {
            return [
                "\(actor) climbed the rankings. \(favorite) has received the disrespect memo and a fresh supply of spite.",
                "Poll voters love \(actor). \(favorite) now gets to answer with the only ranking that matters.",
            ]
        }
        if brief.relationship == .favorite {
            return [
                "\(actor) climbed the rankings. Act surprised while quietly printing the receipts.",
                "The poll noticed \(actor). Humility may remain seated until further notice.",
            ]
        }
        return [
            "The rankings moved. Every fan base has immediately filed an appeal.",
            "Poll season: where arithmetic wears a blazer and starts arguments for free.",
        ]
    }

    private func perspectiveAwareGeneralResponses(for brief: ReactionBrief) -> [String] {
        if brief.relationship == .rival,
           let rival = brief.rivalTeam ?? brief.actor,
           let favorite = brief.favoriteTeam {
            return [
                "\(rival) made news. \(favorite) is watching—and absolutely not sending congratulations.",
                "Whatever \(rival) is celebrating, \(favorite) just filed it under future evidence.",
            ]
        }
        if brief.relationship == .favorite, let favorite = brief.favoriteTeam {
            return [
                "\(favorite) made news. The fan base has already upgraded it from development to destiny.",
                "\(favorite) moved the plot. Your group chat is now operating without adult supervision.",
            ]
        }
        return [
            "I need the replay, the stakes, and one brave witness. This smells consequential.",
            "Give me one team and one consequence. The league office will supply the judgment.",
        ]
    }
}
