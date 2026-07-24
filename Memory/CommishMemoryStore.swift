import Foundation
import SwiftData

@MainActor
final class CommishMemoryStore {
    private let context: ModelContext
    private let maximumMemories = 12
    private let maximumReactionFeedback = 200

    init(context: ModelContext) {
        self.context = context
    }

    func profile() -> FanProfile? {
        var descriptor = FetchDescriptor<FanProfile>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func memories() -> [CommishMemory] {
        let descriptor = FetchDescriptor<CommishMemory>(sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func policyAdjustments() -> [ReactionPolicyAdjustment] {
        let descriptor = FetchDescriptor<LearnedReactionPreference>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return ((try? context.fetch(descriptor)) ?? []).compactMap { preference in
            guard
                abs(preference.weight) >= 0.01,
                let action = CommishAction(rawValue: preference.action),
                let emotion = CommishEmotion(rawValue: preference.emotion)
            else {
                return nil
            }
            return ReactionPolicyAdjustment(
                featureKey: preference.featureKey,
                action: action,
                emotion: emotion,
                weight: preference.weight
            )
        }
    }

    @discardableResult
    func recordReactionFeedback(
        _ snapshot: ReactionFeedbackSnapshot,
        correction: ReactionCorrectionOption?
    ) -> Bool {
        let featureKeys = Array(Set(snapshot.featureKeys)).sorted()
        guard !featureKeys.isEmpty else { return false }

        context.insert(
            ReactionFeedback(
                eventText: snapshot.eventText,
                featureKeys: featureKeys,
                predictedAction: snapshot.predictedAction,
                predictedEmotion: snapshot.predictedEmotion,
                correctedAction: correction?.action,
                correctedEmotion: correction?.emotion,
                providerName: snapshot.providerName,
                line: snapshot.line,
                isPositive: correction == nil
            )
        )

        if let correction {
            for featureKey in featureKeys {
                updatePreference(
                    featureKey: featureKey,
                    action: snapshot.predictedAction,
                    emotion: snapshot.predictedEmotion,
                    delta: -0.65
                )
                updatePreference(
                    featureKey: featureKey,
                    action: correction.action,
                    emotion: correction.emotion,
                    delta: 1.0
                )
            }
        } else {
            for featureKey in featureKeys {
                updatePreference(
                    featureKey: featureKey,
                    action: snapshot.predictedAction,
                    emotion: snapshot.predictedEmotion,
                    delta: 0.08
                )
            }
        }

        trimReactionFeedback()
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    func reconcileProfileBackedMemories() {
        let profileCategories = Set([
            MemoryDecision.favoriteTeam.rawValue,
            MemoryDecision.rivalTeam.rawValue,
            MemoryDecision.preferredTone.rawValue,
        ])
        let stale = memories().filter { profileCategories.contains($0.category) }
        guard !stale.isEmpty else { return }
        stale.forEach(context.delete)
        try? context.save()
    }

    @discardableResult
    func save(_ candidate: MemoryCandidate) -> Bool {
        if candidate.category != .recurringInterest {
            return updateProfile(with: candidate)
        }

        let category = candidate.category.rawValue
        let normalized = candidate.value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        if let existing = memories().first(where: {
            $0.category == category &&
            $0.value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == normalized
        }) {
            existing.lastUsedAt = .now
            existing.confidence = max(existing.confidence, candidate.confidence)
            try? context.save()
            return false
        }

        let current = memories()
        if current.count >= maximumMemories, let oldest = current.min(by: { $0.lastUsedAt < $1.lastUsedAt }) {
            context.delete(oldest)
        }
        context.insert(CommishMemory(category: category, value: candidate.value, confidence: candidate.confidence))
        try? context.save()
        return true
    }

    private func updateProfile(with candidate: MemoryCandidate) -> Bool {
        let value = candidate.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = profile() ?? {
            let created = FanProfile(
                favoriteTeam: "",
                rivalTeam: "",
                preferredCommishTone: "playful",
                currentStreak: 0,
                oregonHelmetsCracked: 0,
                ohioStateHelmetsCracked: 0,
                isDemoData: false
            )
            context.insert(created)
            return created
        }()

        let oldValue: String
        switch candidate.category {
        case .favoriteTeam:
            oldValue = profile.favoriteTeam
            profile.favoriteTeam = value
        case .rivalTeam:
            oldValue = profile.rivalTeam
            profile.rivalTeam = value
        case .preferredTone:
            oldValue = profile.preferredCommishTone
            profile.preferredCommishTone = value
        case .recurringInterest, .none:
            return false
        }

        let changed = oldValue.compare(value, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame
        profile.isDemoData = false
        profile.updatedAt = .now
        reconcileProfileBackedMemories()
        try? context.save()
        return changed
    }

    func delete(_ memory: CommishMemory) {
        context.delete(memory)
        try? context.save()
    }

    func forgetEverything() {
        memories().forEach(context.delete)
        if let profiles = try? context.fetch(FetchDescriptor<FanProfile>()) {
            profiles.forEach(context.delete)
        }
        if let feedback = try? context.fetch(FetchDescriptor<ReactionFeedback>()) {
            feedback.forEach(context.delete)
        }
        if let preferences = try? context.fetch(FetchDescriptor<LearnedReactionPreference>()) {
            preferences.forEach(context.delete)
        }
        try? context.save()
    }

    private func updatePreference(
        featureKey: String,
        action: CommishAction,
        emotion: CommishEmotion,
        delta: Double
    ) {
        let actionRawValue = action.rawValue
        let emotionRawValue = emotion.rawValue
        let descriptor = FetchDescriptor<LearnedReactionPreference>(
            predicate: #Predicate {
                $0.featureKey == featureKey
                    && $0.action == actionRawValue
                    && $0.emotion == emotionRawValue
            }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.weight = min(3, max(-3, existing.weight + delta))
            existing.evidenceCount += 1
            existing.updatedAt = .now
        } else {
            context.insert(
                LearnedReactionPreference(
                    featureKey: featureKey,
                    action: action,
                    emotion: emotion,
                    weight: delta
                )
            )
        }
    }

    private func trimReactionFeedback() {
        let descriptor = FetchDescriptor<ReactionFeedback>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let feedback = (try? context.fetch(descriptor)) ?? []
        guard feedback.count > maximumReactionFeedback else { return }
        feedback.dropFirst(maximumReactionFeedback).forEach(context.delete)
    }
}
