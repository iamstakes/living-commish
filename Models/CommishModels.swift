import Foundation
import FoundationModels

@Generable
enum CommishAction: String, Codable, CaseIterable, Sendable, Identifiable {
    case idle
    case pointRight
    case sadShrug
    case wave
    case foamFinger

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .idle: "Idle"
        case .pointRight: "Point Right"
        case .sadShrug: "Sad Shrug"
        case .wave: "Wave"
        case .foamFinger: "Foam Finger"
        }
    }

    var symbolName: String {
        switch self {
        case .idle: "figure.stand"
        case .pointRight: "hand.point.right.fill"
        case .sadShrug: "cloud.rain.fill"
        case .wave: "hand.wave.fill"
        case .foamFinger: "hand.point.up.left.fill"
        }
    }
}

@Generable
enum CommishEmotion: String, Codable, CaseIterable, Sendable {
    case neutral
    case curious
    case smug
    case annoyed
    case disappointed
    case encouraging
    case celebratory

    var displayName: String {
        switch self {
        case .neutral: "Composed"
        case .curious: "Locked In"
        case .smug: "Judgmental"
        case .annoyed: "Irritated"
        case .disappointed: "Devastated"
        case .encouraging: "Rallying"
        case .celebratory: "Electric"
        }
    }
}

@Generable
enum MemoryDecision: String, Codable, CaseIterable, Sendable {
    case none
    case favoriteTeam
    case rivalTeam
    case preferredTone
    case recurringInterest
}

@Generable
struct CommishReaction: Codable, Equatable, Sendable {
    @Guide(description: "A specific, vivid, emotionally opinionated sports commissioner reaction containing no more than 18 words; never a generic acknowledgment.")
    var line: String
    var action: CommishAction
    var emotion: CommishEmotion
    var memoryDecision: MemoryDecision
    @Guide(description: "Only an explicit durable preference from the fan event, or nil.")
    var memoryValue: String?
}

struct FanEvent: Equatable, Sendable {
    let text: String
}

enum FanEventIntent: String, Equatable, Hashable, Sendable {
    case attendance
    case celebration
    case result
    case question
    case explanation
    case challenge
    case greeting
    case news
    case health
    case unknown
}

struct FanEventSignals: Equatable, Sendable {
    let intent: FanEventIntent
    let valence: Double
    let arousal: Double
    let isAnticipatory: Bool
    let isFavoriteTradition: Bool
    let traditionName: String?

    var featureKeys: [String] {
        var keys = [
            "intent:\(intent.rawValue)",
            "valence:\(valence >= 0.35 ? "positive" : valence <= -0.35 ? "negative" : "neutral")",
            "arousal:\(arousal >= 0.7 ? "high" : arousal >= 0.35 ? "medium" : "low")",
        ]
        if isAnticipatory { keys.append("stance:anticipatory") }
        if isFavoriteTradition { keys.append("relationship:favoriteTradition") }
        if let traditionName { keys.append("tradition:\(traditionName.lowercased())") }
        return keys
    }
}

struct ReactionPolicyAdjustment: Equatable, Sendable {
    let featureKey: String
    let action: CommishAction
    let emotion: CommishEmotion
    let weight: Double
}

struct ReactionFeedbackSnapshot: Equatable, Sendable {
    let eventText: String
    let featureKeys: [String]
    let predictedAction: CommishAction
    let predictedEmotion: CommishEmotion
    let providerName: String
    let line: String
}

enum ReactionCorrectionOption: String, CaseIterable, Identifiable, Sendable {
    case celebrate
    case encourage
    case investigate
    case annoyed
    case disappointed
    case neutral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .celebrate: "More excited"
        case .encourage: "More supportive"
        case .investigate: "More curious"
        case .annoyed: "More irritated"
        case .disappointed: "More disappointed"
        case .neutral: "Less dramatic"
        }
    }

    var action: CommishAction {
        switch self {
        case .celebrate: .foamFinger
        case .encourage: .wave
        case .investigate, .annoyed: .pointRight
        case .disappointed: .sadShrug
        case .neutral: .idle
        }
    }

    var emotion: CommishEmotion {
        switch self {
        case .celebrate: .celebratory
        case .encourage: .encouraging
        case .investigate: .curious
        case .annoyed: .annoyed
        case .disappointed: .disappointed
        case .neutral: .neutral
        }
    }
}

enum ReactionTopic: String, Equatable, Hashable, Sendable {
    case attendance
    case helmet
    case streakExtended
    case streakLost
    case correct
    case incorrect
    case challenge
    case explanation
    case opinion
    case greeting
    case recruiting
    case transfer
    case injury
    case ranking
    case rivalryWin
    case dominantWin
    case dominantLoss
    case heartbreak
    case upset
    case win
    case loss
    case controversy
    case news
    case unknown
}

enum FanRelationship: String, Equatable, Sendable {
    case favorite
    case rival
    case other
    case unknown
}

enum FanImpact: String, Equatable, Sendable {
    case positive
    case negative
    case mixed
    case neutral
}

struct ReactionBrief: Equatable, Sendable {
    let eventText: String
    let topic: ReactionTopic
    let signals: FanEventSignals
    let actor: String?
    let target: String?
    let stakes: String?
    let favoriteTeam: String?
    let rivalTeam: String?
    let preferredTone: String
    let currentStreak: Int?
    let opponent: String?
    let opponentHelmetCount: Int?
    let relationship: FanRelationship
    let fanImpact: FanImpact
    let desiredAction: CommishAction
    let desiredEmotion: CommishEmotion

    var learningFeatureKeys: [String] {
        signals.featureKeys + [
            "topic:\(topic.rawValue)",
            "relationship:\(relationship.rawValue)",
            "impact:\(fanImpact.rawValue)",
        ]
    }

    var compactPrompt: String {
        var facts = [
            "Event: \(eventText)",
            "Semantic topic: \(topic.rawValue)",
            "Fan intent: \(signals.intent.rawValue)",
            "Sentiment valence: \(String(format: "%.2f", signals.valence))",
            "Emotional intensity: \(String(format: "%.2f", signals.arousal))",
            "Fan relationship to actor: \(relationship.rawValue)",
            "Likely emotional impact on fan: \(fanImpact.rawValue)",
            "Preferred tone: \(preferredTone)",
        ]
        if let favoriteTeam { facts.append("Favorite team: \(favoriteTeam)") }
        if let rivalTeam { facts.append("Rival team: \(rivalTeam)") }
        if let actor { facts.append("Event actor: \(actor)") }
        if let target { facts.append("Event target: \(target)") }
        if let stakes { facts.append("Stakes: \(stakes)") }
        if let currentStreak { facts.append("Current streak: \(currentStreak)") }
        if let opponent { facts.append("Event opponent: \(opponent)") }
        if let opponentHelmetCount { facts.append("Stored helmet count for opponent: \(opponentHelmetCount)") }
        facts.append("Editorial angle: \(editorialAngle)")
        facts.append("Treat the favorite/rival relationship as mandatory perspective, not optional decoration.")
        return facts.joined(separator: "\n")
    }

    private var editorialAngle: String {
        switch topic {
        case .attendance:
            "Share the fan's anticipation. Treat attending a favorite-team tradition as a celebratory moment."
        case .recruiting where relationship == .rival:
            "The rival added elite talent, increasing competitive pressure on the favorite team. Express irritation, not panic."
        case .recruiting where relationship == .favorite:
            "Celebrate the talent while warning that expectations just became heavier."
        case .transfer where relationship == .rival:
            "Treat the rival's roster move as an irritating escalation for the favorite team."
        case .transfer:
            "Treat the roster change as motion with consequences, not administrative news."
        case .injury:
            "Drop rivalry jokes and make health more important than the scoreboard."
        case .ranking where relationship == .rival:
            "Treat the rival's status as a temporary insult the favorite team must answer."
        case .ranking:
            "Treat the ranking as pressure, not a trophy."
        case .dominantWin:
            "State plainly that the winner controlled the result from start to finish."
        case .dominantLoss, .heartbreak:
            "Make the pain specific, then leave the fan with dignity."
        case .upset:
            "State how decisively the underdog overturned expectations."
        case .win, .rivalryWin:
            "Grant temporary, theatrical bragging rights."
        case .loss, .streakLost, .incorrect:
            "Acknowledge the bruise, then point toward the next possession."
        case .helmet:
            "Celebrate the repeated achievement with dry commissioner humor."
        case .streakExtended:
            "Celebrate the growing streak and the fan's consistency."
        case .correct:
            "Rule decisively, as if closing a replay review."
        case .challenge:
            "Challenge the fan to support confidence with evidence."
        case .explanation:
            "Explain the emotional stakes and lasting bragging rights directly."
        case .opinion:
            "State a thesis and the mechanism behind it."
        case .greeting:
            "Welcome the fan into a league office already processing fresh chaos."
        case .controversy:
            "Put common sense and the official ruling into conflict."
        case .news, .unknown:
            "Find the consequence for this fan instead of announcing that news occurred."
        default:
            "Make the consequence for this fan specific."
        }
    }
}

enum CommishReactionValidationError: LocalizedError, Equatable {
    case emptyLine
    case tooManyWords(Int)
    case invalidMemoryValue

    var errorDescription: String? {
        switch self {
        case .emptyLine: "The generated reaction was empty."
        case .tooManyWords(let count): "The generated reaction had \(count) words; the limit is 18."
        case .invalidMemoryValue: "The generated memory candidate was not valid."
        }
    }
}

enum CommishReactionValidator {
    static func validate(_ reaction: CommishReaction) throws -> CommishReaction {
        let line = reaction.line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { throw CommishReactionValidationError.emptyLine }
        let wordCount = line.split(whereSeparator: { $0.isWhitespace }).count
        guard wordCount <= 18 else { throw CommishReactionValidationError.tooManyWords(wordCount) }
        if reaction.memoryDecision == .none, reaction.memoryValue != nil {
            throw CommishReactionValidationError.invalidMemoryValue
        }
        if reaction.memoryDecision != .none {
            guard let value = reaction.memoryValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                  (2...40).contains(value.count) else {
                throw CommishReactionValidationError.invalidMemoryValue
            }
        }
        var cleaned = reaction
        cleaned.line = line
        cleaned.memoryValue = reaction.memoryValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
}
