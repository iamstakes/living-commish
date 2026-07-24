import Foundation
import SwiftData

@Model
final class FanProfile {
    var favoriteTeam: String
    var rivalTeam: String
    var preferredCommishTone: String
    var currentStreak: Int
    var oregonHelmetsCracked: Int
    var ohioStateHelmetsCracked: Int
    var isDemoData: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        favoriteTeam: String,
        rivalTeam: String,
        preferredCommishTone: String,
        currentStreak: Int,
        oregonHelmetsCracked: Int,
        ohioStateHelmetsCracked: Int,
        isDemoData: Bool = true
    ) {
        self.favoriteTeam = favoriteTeam
        self.rivalTeam = rivalTeam
        self.preferredCommishTone = preferredCommishTone
        self.currentStreak = currentStreak
        self.oregonHelmetsCracked = oregonHelmetsCracked
        self.ohioStateHelmetsCracked = ohioStateHelmetsCracked
        self.isDemoData = isDemoData
        self.createdAt = .now
        self.updatedAt = .now
    }
}

@Model
final class CommishMemory {
    var category: String
    var value: String
    var confidence: Double
    var createdAt: Date
    var lastUsedAt: Date

    init(category: String, value: String, confidence: Double = 1.0) {
        self.category = category
        self.value = value
        self.confidence = confidence
        self.createdAt = .now
        self.lastUsedAt = .now
    }
}

struct MemoryCandidate: Equatable, Sendable {
    let category: MemoryDecision
    let value: String
    let confidence: Double
}

@Model
final class ReactionFeedback {
    var eventText: String
    var featureKeys: String
    var predictedAction: String
    var predictedEmotion: String
    var correctedAction: String?
    var correctedEmotion: String?
    var providerName: String
    var line: String
    var isPositive: Bool
    var createdAt: Date

    init(
        eventText: String,
        featureKeys: [String],
        predictedAction: CommishAction,
        predictedEmotion: CommishEmotion,
        correctedAction: CommishAction?,
        correctedEmotion: CommishEmotion?,
        providerName: String,
        line: String,
        isPositive: Bool
    ) {
        self.eventText = eventText
        self.featureKeys = featureKeys.joined(separator: "\u{1F}")
        self.predictedAction = predictedAction.rawValue
        self.predictedEmotion = predictedEmotion.rawValue
        self.correctedAction = correctedAction?.rawValue
        self.correctedEmotion = correctedEmotion?.rawValue
        self.providerName = providerName
        self.line = line
        self.isPositive = isPositive
        self.createdAt = .now
    }
}

@Model
final class LearnedReactionPreference {
    var featureKey: String
    var action: String
    var emotion: String
    var weight: Double
    var evidenceCount: Int
    var updatedAt: Date

    init(
        featureKey: String,
        action: CommishAction,
        emotion: CommishEmotion,
        weight: Double,
        evidenceCount: Int = 1
    ) {
        self.featureKey = featureKey
        self.action = action.rawValue
        self.emotion = emotion.rawValue
        self.weight = weight
        self.evidenceCount = evidenceCount
        self.updatedAt = .now
    }
}
