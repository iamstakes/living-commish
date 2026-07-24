import Foundation

enum ReactionBriefBuilder {
    static func build(
        for event: FanEvent,
        profile: FanProfile?,
        adjustments: [ReactionPolicyAdjustment] = []
    ) -> ReactionBrief {
        let text = event.text.lowercased()
        let favorite = cleaned(profile?.favoriteTeam)
        let rival = cleaned(profile?.rivalTeam)
        let signals = FanEventSignalExtractor.extract(
            from: event.text,
            favoriteTeam: favorite
        )
        let topic = classify(text, signals: signals)
        let participants = participants(for: event.text, topic: topic)
        let mentionedKnownTeam = knownTeamMention(in: event.text, favorite: favorite, rival: rival)
        let actor = participants.actor
            ?? mentionedKnownTeam
            ?? (signals.isFavoriteTradition ? favorite : nil)
        let target = participants.target
        let relationship = relationship(
            actor: actor,
            target: target,
            eventText: event.text,
            favorite: favorite,
            rival: rival
        )
        let impact = fanImpact(
            topic: topic,
            relationship: relationship,
            actor: actor,
            target: target,
            favorite: favorite,
            rival: rival,
            text: text,
            signals: signals
        )
        let performance = ReactionPolicy.plan(
            topic: topic,
            relationship: relationship,
            impact: impact,
            signals: signals,
            adjustments: adjustments
        )

        let opponent: String?
        let helmetCount: Int?
        if text.contains("oregon") {
            opponent = "Oregon"
            helmetCount = topic == .helmet ? profile?.oregonHelmetsCracked : nil
        } else if text.contains("ohio state") {
            opponent = "Ohio State"
            helmetCount = topic == .helmet ? profile?.ohioStateHelmetsCracked : nil
        } else {
            opponent = target
            helmetCount = nil
        }

        return ReactionBrief(
            eventText: event.text,
            topic: topic,
            signals: signals,
            actor: actor,
            target: target,
            stakes: participants.stakes,
            favoriteTeam: favorite,
            rivalTeam: rival,
            preferredTone: profile?.preferredCommishTone.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "playful",
            currentStreak: topic == .streakExtended || topic == .streakLost ? profile?.currentStreak : nil,
            opponent: opponent,
            opponentHelmetCount: helmetCount,
            relationship: relationship,
            fanImpact: impact,
            desiredAction: performance.action,
            desiredEmotion: performance.emotion
        )
    }

    private static func classify(_ text: String, signals: FanEventSignals) -> ReactionTopic {
        if signals.intent == .attendance { return .attendance }
        if text.contains("helmet") || text.contains("cracked") { return .helmet }
        if text.contains("lost") && text.contains("streak") { return .streakLost }
        if (text.contains("extended") || text.contains("day streak")) && text.contains("streak") { return .streakExtended }
        if containsAny(text, ["recruit", "signed", "commitment", "committed", "five-star", "5-star"]) { return .recruiting }
        if containsAny(text, ["transfer portal", "transferred", "transfer"]) { return .transfer }
        if containsAny(text, ["injured", "injury", "out for the season", "torn acl"]) { return .injury }
        if containsAny(text, ["ranked", "ranking", "top 25", "number one", "no. 1", "#1"]) { return .ranking }
        if text.contains("beat ohio state") || text.contains("rivalry win") { return .rivalryWin }
        if text.contains("incorrect") || text.contains("wrong answer") { return .incorrect }
        if text.contains("correct") || text.contains("right answer") || text.contains("won today") { return .correct }
        if containsAny(text, ["what do you think", "do you agree", "your take", "your opinion", "thoughts on"]) { return .opinion }
        if text.contains("explain") || text.contains("why") { return .explanation }
        if text.contains("challenge") || text.contains("bet you") { return .challenge }
        if text.contains("hello") || text.contains("hi ") || text == "hi" || text.contains("hey") { return .greeting }
        if containsAny(text, ["robbed", "bad call", "terrible call", "referee", "refs ", "officiating", "rigged"]) { return .controversy }

        let dominantTerms = ["embarrassed", "humiliated", "destroyed", "demolished", "crushed", "routed", "smoked", "thrashed", "blown out"]
        if containsAny(text, dominantTerms) {
            let lossFraming = (text.contains(" was ") && text.contains(" by "))
                || (text.contains(" were ") && text.contains(" by "))
                || text.contains("lost to")
                || text.contains("got embarrassed")
                || text.contains("got destroyed")
                || text.contains("got crushed")
            return lossFraming ? .dominantLoss : .dominantWin
        }

        let highStakesTerms = ["final", "championship", "overtime", "shootout", "playoff"]
        let lossTerms = ["lost", "fell to", "defeated by", "eliminated", "choked"]
        if containsAny(text, highStakesTerms), containsAny(text, lossTerms) { return .heartbreak }
        if containsAny(text, ["upset", "stunned the favorite", "shocked the favorite"]) { return .upset }
        let winTerms = [" beat ", "defeated", "won ", "victory", "took down", "knocked out"]
        if containsAny(text, winTerms) || text.hasPrefix("beat ") || text.hasPrefix("won ") { return .win }
        if containsAny(text, lossTerms) { return .loss }
        if containsAny(text, ["announced", "named", "hired", "fired", "news", "breaking"]) { return .news }
        return .unknown
    }

    private static func participants(for rawText: String, topic: ReactionTopic) -> (actor: String?, target: String?, stakes: String?) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        var actor: String?
        var target: String?

        if topic == .recruiting || topic == .transfer || topic == .injury || topic == .ranking || topic == .news {
            actor = firstCapture(
                in: text,
                pattern: #"^\s*(.+?)\s+(?:just\s+)?(?:signed|landed|added|got|secured|announced|hired|fired|is|was|rose|fell|ranked|lost)"#
            ).map(compactName)
        }

        if let captures = capture(
            in: text,
            pattern: #"^\s*(.+?)\s+(?:was|were)\s+(?:embarrassed|humiliated|destroyed|demolished|crushed|routed|smoked|thrashed|blown out)\s+by\s+(.+?)(?=\s+(?:in|at|during)\s+|[.!?]*\s*$)"#
        ) {
            target = compactName(captures.0)
            actor = compactName(captures.1)
        } else if let captures = capture(
            in: text,
            pattern: #"^\s*(.+?)\s+(?:beat|defeated|embarrassed|humiliated|destroyed|demolished|crushed|routed|smoked|thrashed|upset|took down|knocked out)\s+(.+?)(?=\s+(?:in|at|during)\s+|[.!?]*\s*$)"#
        ) {
            actor = compactName(captures.0)
            target = compactName(captures.1)
        } else if let captures = capture(
            in: text,
            pattern: #"^\s*(.+?)\s+(?:lost|fell)\s+to\s+(.+?)(?=\s+(?:in|at|during)\s+|[.!?]*\s*$)"#
        ) {
            target = compactName(captures.0)
            actor = compactName(captures.1)
        }

        let capturedStage = firstCapture(
            in: text,
            pattern: #"\b(?:in|at|during)\s+((?:the\s+)?[^.!?]+)"#
        )
        let stakes = capturedStage.flatMap {
            containsAny($0.lowercased(), ["final", "championship", "overtime", "shootout", "playoff"]) ? compactPhrase($0) : nil
        }
        return (actor, target, stakes)
    }

    private static func relationship(
        actor: String?,
        target: String?,
        eventText: String,
        favorite: String?,
        rival: String?
    ) -> FanRelationship {
        if matches(actor, favorite) { return .favorite }
        if matches(actor, rival) { return .rival }
        if actor == nil {
            if containsTeam(eventText, team: rival) { return .rival }
            if containsTeam(eventText, team: favorite) { return .favorite }
        }
        if matches(target, favorite) || matches(target, rival) { return .other }
        return actor == nil ? .unknown : .other
    }

    private static func fanImpact(
        topic: ReactionTopic,
        relationship: FanRelationship,
        actor: String?,
        target: String?,
        favorite: String?,
        rival: String?,
        text: String,
        signals: FanEventSignals
    ) -> FanImpact {
        if signals.intent == .attendance {
            return signals.valence >= 0 ? .positive : .mixed
        }
        if topic == .injury {
            return relationship == .favorite ? .negative : .mixed
        }
        if topic == .rivalryWin { return .positive }
        if [.recruiting, .ranking, .transfer, .news, .unknown].contains(topic) {
            if relationship == .favorite { return text.contains("lost") || text.contains("fell") ? .negative : .positive }
            if relationship == .rival { return text.contains("lost") || text.contains("fell") ? .positive : .negative }
        }
        if [.win, .dominantWin, .upset].contains(topic) {
            if matches(actor, favorite) || matches(target, rival) { return .positive }
            if matches(actor, rival) || matches(target, favorite) { return .negative }
            return .positive
        }
        if [.loss, .dominantLoss, .heartbreak, .streakLost, .incorrect].contains(topic) {
            return .negative
        }
        if [.helmet, .streakExtended, .correct].contains(topic) { return .positive }
        if topic == .controversy { return .mixed }
        return .neutral
    }

    private static func knownTeamMention(in text: String, favorite: String?, rival: String?) -> String? {
        if containsTeam(text, team: rival) { return rival }
        if containsTeam(text, team: favorite) { return favorite }
        if text.localizedCaseInsensitiveContains("Ohio State") { return "Ohio State" }
        if text.localizedCaseInsensitiveContains("Oregon") { return "Oregon" }
        return nil
    }

    private static func containsTeam(_ text: String, team: String?) -> Bool {
        guard let team else { return false }
        return text.localizedCaseInsensitiveContains(team)
    }

    private static func matches(_ left: String?, _ right: String?) -> Bool {
        guard let left = cleaned(left), let right = cleaned(right) else { return false }
        return left.compare(right, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }

    private static func cleaned(_ value: String?) -> String? {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private static func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains(where: text.contains)
    }

    private static func capture(in text: String, pattern: String) -> (String, String)? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 3,
              let firstRange = Range(match.range(at: 1), in: text),
              let secondRange = Range(match.range(at: 2), in: text) else {
            return nil
        }
        return (String(text[firstRange]), String(text[secondRange]))
    }

    private static func firstCapture(in text: String, pattern: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 2,
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private static func compactName(_ raw: String) -> String {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        if cleaned.lowercased() == "i" { return "You" }
        if cleaned.lowercased() == "we" { return "Your side" }
        return cleaned.split(whereSeparator: \.isWhitespace).prefix(3).joined(separator: " ")
    }

    private static func compactPhrase(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .split(whereSeparator: \.isWhitespace)
            .prefix(4)
            .joined(separator: " ")
    }
}

enum FanEventSignalExtractor {
    static func extract(from rawText: String, favoriteTeam: String?) -> FanEventSignals {
        let text = rawText
            .replacingOccurrences(of: "’", with: "'")
            .lowercased()

        let isWhiteout = text.contains("whiteout") || text.contains("white out")
        let attendanceLanguage = containsAny(text, [
            "i'm going", "i am going", "we're going", "we are going", "going to the",
            "headed to", "attending", "got tickets", "have tickets", "will be at",
        ])
        let eventLanguage = containsAny(text, [
            "game", "match", "whiteout", "white out", "stadium", "tailgate",
        ])
        let isAttendance = attendanceLanguage && eventLanguage

        let intent: FanEventIntent
        if isAttendance {
            intent = .attendance
        } else if containsAny(text, ["hello", "hey", "hi "]) || text == "hi" {
            intent = .greeting
        } else if containsAny(text, ["what do you think", "do you agree", "your take", "your opinion", "thoughts on"]) {
            intent = .question
        } else if containsAny(text, ["explain", "why"]) {
            intent = .explanation
        } else if containsAny(text, ["challenge", "bet you"]) {
            intent = .challenge
        } else if containsAny(text, ["injured", "injury", "out for the season", "torn acl"]) {
            intent = .health
        } else if containsAny(text, ["won", "beat", "victory", "lost", "defeated", "eliminated"]) {
            intent = .result
        } else if containsAny(text, ["celebrate", "amazing", "incredible", "let's go", "lets go"]) {
            intent = .celebration
        } else if containsAny(text, ["announced", "signed", "ranked", "breaking", "news"]) {
            intent = .news
        } else {
            intent = .unknown
        }

        let positiveTerms = [
            "excited", "can't wait", "cannot wait", "love", "amazing", "incredible",
            "let's go", "lets go", "won", "victory", "going to", "got tickets",
        ]
        let negativeTerms = [
            "lost", "hate", "awful", "terrible", "injured", "injury", "eliminated",
            "devastated", "worried", "upset",
        ]
        var valence = 0.0
        valence += Double(positiveTerms.filter(text.contains).count) * 0.35
        valence -= Double(negativeTerms.filter(text.contains).count) * 0.45
        if isAttendance { valence += 0.55 }
        if isWhiteout { valence += 0.2 }
        valence = min(1, max(-1, valence))

        let exclamationCount = rawText.filter { $0 == "!" }.count
        let uppercaseWords = rawText
            .split(whereSeparator: \.isWhitespace)
            .filter { word in
                let letters = word.filter(\.isLetter)
                return letters.count >= 3 && String(letters) == String(letters).uppercased()
            }
            .count
        var arousal = 0.16 + min(0.66, Double(exclamationCount) * 0.22)
        arousal += min(0.18, Double(uppercaseWords) * 0.09)
        if containsAny(text, ["so excited", "can't wait", "let's go", "lets go"]) { arousal += 0.2 }
        arousal = min(1, arousal)

        let normalizedFavorite = favoriteTeam?.lowercased() ?? ""
        let isFavoriteTradition = isWhiteout && normalizedFavorite.contains("penn state")
        return FanEventSignals(
            intent: intent,
            valence: valence,
            arousal: arousal,
            isAnticipatory: isAttendance || containsAny(text, ["can't wait", "cannot wait", "looking forward"]),
            isFavoriteTradition: isFavoriteTradition,
            traditionName: isWhiteout ? "Whiteout" : nil
        )
    }

    private static func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains(where: text.contains)
    }
}

enum ReactionPolicy {
    static func plan(
        topic: ReactionTopic,
        relationship: FanRelationship,
        impact: FanImpact,
        signals: FanEventSignals,
        adjustments: [ReactionPolicyAdjustment]
    ) -> (action: CommishAction, emotion: CommishEmotion) {
        var actionScores = Dictionary(
            uniqueKeysWithValues: CommishAction.allCases.map { ($0, 0.0) }
        )
        actionScores[.idle] = 0.4
        actionScores[.pointRight] = -0.8
        actionScores[.sadShrug] = -0.4
        actionScores[.wave] = -0.2
        actionScores[.foamFinger] = -0.2

        var emotionScores = Dictionary(
            uniqueKeysWithValues: CommishEmotion.allCases.map { ($0, 0.0) }
        )
        emotionScores[.neutral] = 0.4

        applyIntent(
            signals,
            impact: impact,
            relationship: relationship,
            actionScores: &actionScores,
            emotionScores: &emotionScores
        )
        applyTopic(
            topic,
            relationship: relationship,
            impact: impact,
            actionScores: &actionScores,
            emotionScores: &emotionScores
        )

        let featureKeys = Set(signals.featureKeys + [
            "topic:\(topic.rawValue)",
            "relationship:\(relationship.rawValue)",
            "impact:\(impact.rawValue)",
        ])
        for adjustment in adjustments where featureKeys.contains(adjustment.featureKey) {
            actionScores[adjustment.action, default: 0] += adjustment.weight
            emotionScores[adjustment.emotion, default: 0] += adjustment.weight
        }

        applyHardConstraints(
            topic: topic,
            relationship: relationship,
            impact: impact,
            signals: signals,
            actionScores: &actionScores,
            emotionScores: &emotionScores
        )

        let action = CommishAction.allCases.max {
            actionScores[$0, default: -100] < actionScores[$1, default: -100]
        } ?? .idle
        let emotion = CommishEmotion.allCases.max {
            emotionScores[$0, default: -100] < emotionScores[$1, default: -100]
        } ?? .neutral
        return (action, emotion)
    }

    private static func applyIntent(
        _ signals: FanEventSignals,
        impact: FanImpact,
        relationship: FanRelationship,
        actionScores: inout [CommishAction: Double],
        emotionScores: inout [CommishEmotion: Double]
    ) {
        switch signals.intent {
        case .attendance:
            actionScores[.foamFinger, default: 0] += 4.2 + signals.arousal * 1.8
            actionScores[.wave, default: 0] += 1.0
            emotionScores[.celebratory, default: 0] += 4.0 + signals.arousal * 2.0
            emotionScores[.encouraging, default: 0] += 0.8
        case .celebration:
            actionScores[.foamFinger, default: 0] += 4.0
            emotionScores[.celebratory, default: 0] += 4.0 + signals.arousal
        case .question, .explanation:
            actionScores[.pointRight, default: 0] += 4.0
            emotionScores[.curious, default: 0] += 3.5
        case .challenge:
            actionScores[.pointRight, default: 0] += 4.0
            emotionScores[.smug, default: 0] += 3.5
        case .greeting:
            actionScores[.wave, default: 0] += 4.0
            emotionScores[.encouraging, default: 0] += 3.0
        case .health:
            actionScores[.sadShrug, default: 0] += 4.0
            emotionScores[.disappointed, default: 0] += 4.0
        case .result:
            if impact == .positive {
                actionScores[.foamFinger, default: 0] += 3.5
                emotionScores[.celebratory, default: 0] += 3.5
            } else {
                actionScores[.sadShrug, default: 0] += 3.5
                emotionScores[.disappointed, default: 0] += 2.5
                emotionScores[.encouraging, default: 0] += 1.5
            }
        case .news:
            if relationship == .rival || impact == .negative {
                actionScores[.pointRight, default: 0] += 2.8
                emotionScores[.annoyed, default: 0] += 3.0
            } else if impact == .positive {
                actionScores[.foamFinger, default: 0] += 2.8
                emotionScores[.celebratory, default: 0] += 2.8
            }
        case .unknown:
            if signals.valence >= 0.35 {
                actionScores[.foamFinger, default: 0] += 1.8 + signals.arousal
                emotionScores[.celebratory, default: 0] += 1.8 + signals.arousal
            } else if signals.valence <= -0.35 {
                actionScores[.sadShrug, default: 0] += 2.0
                emotionScores[.disappointed, default: 0] += 2.0
            } else {
                actionScores[.idle, default: 0] += 1.5
                emotionScores[.neutral, default: 0] += 1.5
            }
        }
    }

    private static func applyTopic(
        _ topic: ReactionTopic,
        relationship: FanRelationship,
        impact: FanImpact,
        actionScores: inout [CommishAction: Double],
        emotionScores: inout [CommishEmotion: Double]
    ) {
        switch topic {
        case .attendance:
            actionScores[.foamFinger, default: 0] += 2.0
            emotionScores[.celebratory, default: 0] += 2.0
        case .helmet, .streakExtended, .correct, .rivalryWin, .dominantWin, .upset, .win:
            if impact == .negative {
                actionScores[.sadShrug, default: 0] += 3.0
                emotionScores[.disappointed, default: 0] += 3.0
            } else {
                actionScores[.foamFinger, default: 0] += 3.0
                emotionScores[.celebratory, default: 0] += 3.0
            }
        case .streakLost, .incorrect, .loss:
            actionScores[.sadShrug, default: 0] += 3.0
            emotionScores[.encouraging, default: 0] += 2.8
        case .dominantLoss, .heartbreak, .injury:
            actionScores[.sadShrug, default: 0] += 4.0
            emotionScores[.disappointed, default: 0] += 4.0
        case .recruiting, .transfer, .ranking, .news:
            if relationship == .rival || impact == .negative {
                actionScores[.pointRight, default: 0] += 3.0
                emotionScores[.annoyed, default: 0] += 3.2
            } else if impact == .positive {
                actionScores[.foamFinger, default: 0] += 3.0
                emotionScores[.celebratory, default: 0] += 3.0
            } else {
                actionScores[.idle, default: 0] += 1.0
                emotionScores[.neutral, default: 0] += 1.0
            }
        case .challenge, .controversy:
            actionScores[.pointRight, default: 0] += 3.5
            emotionScores[.smug, default: 0] += 3.0
        case .explanation, .opinion:
            actionScores[.pointRight, default: 0] += 3.5
            emotionScores[.curious, default: 0] += 3.0
        case .greeting:
            actionScores[.wave, default: 0] += 3.5
            emotionScores[.encouraging, default: 0] += 3.0
        case .unknown:
            break
        }
    }

    private static func applyHardConstraints(
        topic: ReactionTopic,
        relationship: FanRelationship,
        impact: FanImpact,
        signals: FanEventSignals,
        actionScores: inout [CommishAction: Double],
        emotionScores: inout [CommishEmotion: Double]
    ) {
        let pointRightAllowed =
            [.question, .explanation, .challenge].contains(signals.intent)
            || [.opinion, .controversy, .recruiting, .transfer, .ranking, .news].contains(topic)
            || (relationship == .rival && impact == .negative)
        if !pointRightAllowed {
            actionScores[.pointRight] = -100
        }

        if topic == .injury {
            for action in CommishAction.allCases where action != .sadShrug {
                actionScores[action] = -100
            }
            for emotion in CommishEmotion.allCases where emotion != .disappointed {
                emotionScores[emotion] = -100
            }
        }

        if [.loss, .dominantLoss, .heartbreak, .streakLost].contains(topic) {
            actionScores[.foamFinger] = -100
            emotionScores[.celebratory] = -100
        }

        if topic == .attendance && signals.valence >= 0 {
            actionScores[.sadShrug] = -100
            actionScores[.pointRight] = -100
            emotionScores[.disappointed] = -100
            emotionScores[.annoyed] = -100
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
