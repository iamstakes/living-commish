import Foundation
import FoundationModels

enum CommishLineSanitizer {
    static func sanitize(_ rawLine: String) -> String {
        var line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if let expression = try? NSRegularExpression(
            pattern: #"^(?:(?:Point\s*Right|Foam\s*Finger|Sad\s*Shrug|Idle)\s*(?:[\.:!—-]\s*|\s+)|Waves?\s*[\.:!—-]\s*)"#,
            options: [.caseInsensitive]
        ) {
            line = expression.stringByReplacingMatches(
                in: line,
                range: NSRange(line.startIndex..., in: line),
                withTemplate: ""
            )
        }
        if let expression = try? NSRegularExpression(
            pattern: #"\s+(?:Point\s*Right|Foam\s*Finger|Sad\s*Shrug|Idle)\s*[\.!]?\s*$"#,
            options: [.caseInsensitive]
        ) {
            line = expression.stringByReplacingMatches(
                in: line,
                range: NSRange(line.startIndex..., in: line),
                withTemplate: ""
            )
        }
        return line
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum CommishGeneratedLinePolicy {
    static func rejectionReason(for line: String, eventText: String) -> String? {
        let lower = " \(line.lowercased()) "
        let event = eventText.lowercased()

        let figurativePatterns = [
            " like a ", " as if ", " juggler", " juggling", "drop the ball",
            " is a ball", " superpowered", " villain", " bad penny", " metaphor", " analogy",
        ]
        if figurativePatterns.contains(where: lower.contains) {
            return "invented figurative language"
        }
        let genericPatterns = [
            " a blow to ", " bad news for ", " good news for ", " top priority",
        ]
        if genericPatterns.contains(where: lower.contains) {
            return "generic consequence"
        }
        if line.contains("?") {
            return "rhetorical question"
        }
        if [" will ", " gonna ", " going to "].contains(where: lower.contains) {
            return "unsupported prediction"
        }
        let unsupportedClaims = [
            " most ", " best ", " top ", " in the nation", " in the country",
            " elite tier", " recruiting class",
        ]
        if let claim = unsupportedClaims.first(where: { lower.contains($0) && !event.contains($0.trimmingCharacters(in: .whitespaces)) }) {
            return "unsupported claim: \(claim.trimmingCharacters(in: .whitespaces))"
        }

        let footballUnits = [
            "offense", "defense", "quarterback", "receiver", "linebacker",
            "secondary", "offensive line", "defensive line",
        ]
        if let inventedUnit = footballUnits.first(where: { lower.contains($0) && !event.contains($0) }) {
            return "unsupported football unit: \(inventedUnit)"
        }
        return nil
    }
}

enum AppleFoundationModelsError: LocalizedError {
    case unavailable(String)
    case alreadyResponding

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason): "Apple Foundation Model unavailable: \(reason)"
        case .alreadyResponding: "The on-device model is already generating a response."
        }
    }
}

@MainActor
final class AppleFoundationModelsCommishProvider: CommishIntelligenceProviding {
    private(set) var providerName = "Apple Foundation Model"
    private let model = SystemLanguageModel(
        useCase: .general,
        guardrails: .permissiveContentTransformations
    )
    private let localEditor = DeterministicCommishProvider()
    private var session: LanguageModelSession?
    private var responseCount = 0

    var isAvailable: Bool { model.isAvailable }

    var availabilityDescription: String {
        switch model.availability {
        case .available:
            "Available on this device"
        case .unavailable(.deviceNotEligible):
            "This device is not eligible for Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            "Apple Intelligence is not enabled"
        case .unavailable(.modelNotReady):
            "The on-device model is not ready"
        case .unavailable:
            "Apple Intelligence is unavailable for an unknown reason"
        }
    }

    func react(to event: FanEvent, brief: ReactionBrief) async throws -> CommishReaction {
        providerName = "Apple Foundation Model"
        guard isAvailable else { throw AppleFoundationModelsError.unavailable(availabilityDescription) }
        if session == nil || responseCount >= 6 { resetSession() }
        guard let session else { throw AppleFoundationModelsError.unavailable("Session could not be created") }
        guard !session.isResponding else { throw AppleFoundationModelsError.alreadyResponding }

        let generatedLine: String
        if brief.topic == .opinion {
            let assessment = try await session.respond(
                to: """
                Fan claim: \(brief.eventText)
                Fan's favorite team: \(brief.favoriteTeam ?? "not supplied")
                Preferred voice: \(brief.preferredTone)

                Accept the fan's claimed quality as true. Do not challenge, weaken, or reverse it.
                In one plain sentence, explain causally why that quality matters during competition or pressure.
                Do not restate the question or evaluate whether the claim is accurate.
                Do not invent team facts, people, results, recruiting, history, or statistics.
                """,
                options: GenerationOptions(sampling: .greedy, temperature: 0.3, maximumResponseTokens: 70)
            )
#if DEBUG
            print("LivingCommish Apple assessment: \(assessment.content)")
#endif
            let cleanAssessment = sanitizeLine(assessment.content)
            let rewriteSession = LanguageModelSession(
                model: model,
                instructions: """
                You are Living Commish, a sharp theatrical sports commissioner.
                Rewrite supplied reasoning into concise, quotable reactions without changing its meaning or adding facts.
                """
            )
            let candidates = try await rewriteSession.respond(
                to: """
                Source reasoning: \(cleanAssessment)

                Write three distinct Living Commish alternatives, one per line, numbered 1 through 3.
                Every alternative must begin exactly "\(brief.favoriteTeam ?? "The fan's team")'s culture".
                Each alternative must use 18 words or fewer and explain what that culture does when pressure arrives.
                Preserve the causal reasoning without adding facts.
                Do not include quotes, markdown, animation names, or explanation.
                Use plain modern English. Make a direct judgment with a specific consequence.
                Do not use metaphors, analogies, idioms, personification, or wordplay.
                """,
                options: GenerationOptions(sampling: .random(top: 10), temperature: 0.45, maximumResponseTokens: 150)
            )
            if let selected = selectOpinionCandidate(from: candidates.content, brief: brief) {
                generatedLine = selected
            } else {
                let edited = try await localEditor.react(to: event, brief: brief)
                generatedLine = edited.line
                providerName = "Apple + local editor"
            }
            responseCount += 2
        } else {
            let response = try await session.respond(
                to: """
                Write three direct Living Commish takes using this editorial brief:
                \(brief.compactPrompt)

                Return three numbered lines and nothing else.
                Every line must be a complete spoken reaction using 18 words or fewer.
                Use plain modern English. State one grounded competitive implication.
                Treat the event's claim as the only factual premise.
                Do not invent recruits, results, rankings, personnel moves, quotes, statistics, or history.
                Do not invent an affected player, position, offense, defense, unit, or future outcome.
                The favorite/rival relationship is product truth. For rival success, name both teams and state the increased pressure on the favorite.
                Do not address a team as "you." Do not use a question.
                Do not use metaphors, analogies, idioms, personification, or wordplay.
                Do not merely restate the event.
                Never print an action or emotion label.
                """,
                options: GenerationOptions(sampling: .random(top: 10), temperature: 0.45, maximumResponseTokens: 150)
            )
            if let selected = selectGeneralCandidate(from: response.content, brief: brief) {
                generatedLine = selected
            } else {
                let edited = try await localEditor.react(to: event, brief: brief)
                generatedLine = edited.line
                providerName = "Apple + local editor"
#if DEBUG
                print("LivingCommish used the local editor after Apple returned no acceptable candidate.")
#endif
            }
            responseCount += 1
        }
#if DEBUG
        print("LivingCommish Apple selected response: \(generatedLine)")
#endif
        let reaction = CommishReaction(
            line: sanitizeLine(generatedLine),
            action: brief.desiredAction,
            emotion: brief.desiredEmotion,
            memoryDecision: .none,
            memoryValue: nil
        )
        return try CommishReactionValidator.validate(reaction)
    }

    func resetSession() {
        session = LanguageModelSession(model: model, instructions: CommishInstructions.stable)
        localEditor.resetSession()
        providerName = "Apple Foundation Model"
        responseCount = 0
    }

    private func sanitizeLine(_ rawLine: String) -> String {
        CommishLineSanitizer.sanitize(rawLine)
    }

    private func selectGeneralCandidate(from rawCandidates: String, brief: ReactionBrief) -> String? {
#if DEBUG
        print("LivingCommish Apple general candidates: \(rawCandidates)")
#endif
        let forbidden = [
            "point right", "pointright", "foam finger", "foamfinger", "sad shrug", "sadshrug",
            "curveball", "making moves", "watch out", "plot thickens", "made news",
            "statement move", "league notice", "game-changer", "not worried",
        ]
        let candidates = parsedCandidates(from: rawCandidates)
        let scored = candidates.compactMap { candidate -> (line: String, score: Int)? in
            let line = sanitizeLine(candidate)
            let lower = line.lowercased()
            let words = line.split(whereSeparator: \.isWhitespace).count
            guard (4...18).contains(words) else { return nil }
            guard !forbidden.contains(where: lower.contains) else { return nil }
            guard CommishGeneratedLinePolicy.rejectionReason(
                for: line,
                eventText: brief.eventText
            ) == nil else { return nil }
            if let actor = brief.actor {
                guard lower.contains(actor.lowercased()) else { return nil }
            }
            if brief.relationship == .rival, let favorite = brief.favoriteTeam {
                guard lower.contains(favorite.lowercased()) else { return nil }
                guard !lower.contains("good for \(favorite.lowercased())") else { return nil }
            }
            if brief.topic == .recruiting {
                let recruitingTerms = ["recruit", "five-star", "5-star", "talent"]
                guard recruitingTerms.contains(where: lower.contains) else { return nil }
            }

            var score = 10 - abs(words - 13)
            if line.contains("—") || line.contains(";") || line.contains(":") { score += 3 }
            if lower.contains("just signed") || lower.contains("just announced") { score -= 6 }
            if brief.topic == .recruiting, brief.relationship == .rival {
                if lower.contains("pressure") || lower.contains("margin") || lower.contains("standard") || lower.contains("answer") {
                    score += 10
                }
                if lower.contains("recruit") || lower.contains("five-star") || lower.contains("5-star") || lower.contains("talent") {
                    score += 7
                }
            }
            return (line, score)
        }

        return scored.max(by: { $0.score < $1.score })?.line
    }

    private func selectOpinionCandidate(from rawCandidates: String, brief: ReactionBrief) -> String? {
#if DEBUG
        print("LivingCommish Apple opinion candidates: \(rawCandidates)")
#endif
        let favoriteTeam = brief.favoriteTeam
        let forbidden = [
            "point right", "pointright", "foam finger", "foamfinger", "sad shrug", "sadshrug",
            "well-oiled", "secret sauce", "game-changer", "culture is the glue", "team's foundation",
            "invisible glue", "the engine that drives", "teams have a culture", "structural integrity",
            "culture like penn state", "much like",
        ]
        let candidates = parsedCandidates(from: rawCandidates)

        let scored = candidates.compactMap { candidate -> (line: String, score: Int)? in
            var line = sanitizeLine(candidate)
            if let favoriteTeam, !line.localizedCaseInsensitiveContains(favoriteTeam) {
                if line.localizedCaseInsensitiveContains("the team") {
                    line = line.replacingOccurrences(
                        of: "the team",
                        with: favoriteTeam,
                        options: .caseInsensitive
                    )
                } else if line.localizedCaseInsensitiveContains("a team") {
                    line = line.replacingOccurrences(
                        of: "a team",
                        with: favoriteTeam,
                        options: .caseInsensitive
                    )
                }
            }
            let words = line.split(whereSeparator: \.isWhitespace).count
            guard (4...18).contains(words) else { return nil }
            let lower = line.lowercased()
            guard !forbidden.contains(where: lower.contains) else { return nil }
            guard CommishGeneratedLinePolicy.rejectionReason(
                for: line,
                eventText: brief.eventText
            ) == nil else { return nil }
            if let favoriteTeam {
                guard lower.contains(favoriteTeam.lowercased()) else { return nil }
            }

            var score = 10 - abs(words - 13)
            if let favoriteTeam, lower.contains(favoriteTeam.lowercased()) { score += 20 }
            if let favoriteTeam,
               lower.hasPrefix("\(favoriteTeam.lowercased())'s culture") {
                score += 12
            }
            if line.contains("—") || line.contains(";") || line.contains(":") { score += 3 }
            if lower.contains("pressure") { score += 4 }
            if lower.contains("especially") || lower.contains("important") || lower.contains("matters") { score -= 5 }
            if lower.contains("culture matters") || lower.contains("brings people together") { score -= 5 }
            return (line, score)
        }
        return scored.max(by: { $0.score < $1.score })?.line
    }

    private func parsedCandidates(from rawCandidates: String) -> [String] {
        rawCandidates
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .map { line in
                line.replacingOccurrences(
                    of: #"^\s*(?:\d+[\.\)]|[-•])\s*"#,
                    with: "",
                    options: .regularExpression
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }
}
