import Foundation
import Observation
import SwiftData

struct CommishLogEntry: Identifiable, Sendable {
    let id = UUID()
    let date = Date()
    let message: String
}

struct DemoScenario: Identifiable, Sendable {
    let id: String
    let title: String
    let event: String
    let symbol: String

    static let all: [DemoScenario] = [
        .init(id: "helmet", title: "Cracked Helmet", event: "I cracked another Oregon helmet.", symbol: "burst.fill"),
        .init(id: "extended", title: "Extended Streak", event: "I extended my streak to eight days.", symbol: "flame.fill"),
        .init(id: "lost", title: "Lost Streak", event: "I lost my seven-day streak.", symbol: "arrow.counterclockwise"),
        .init(id: "rivalry", title: "Rivalry Win", event: "I beat Ohio State in today’s Blitz.", symbol: "trophy.fill"),
        .init(id: "explain", title: "Needs Explanation", event: "Explain why this matchup matters.", symbol: "questionmark.bubble.fill"),
    ]
}

@MainActor
@Observable
final class AppEnvironment {
    let commish = AdaptiveCommishController()
    let intelligence = AdaptiveCommishIntelligenceProvider(
        forceLocalFallback: ProcessInfo.processInfo.arguments.contains("--ui-testing")
    )

    var inputText = ""
    var responseLine = "Report the play. I’ll decide how much dignity survives."
    var currentEmotion: CommishEmotion = .curious
    var isGenerating = false
    var isMemoryPresented = false
    var logs: [CommishLogEntry] = []
    var feedbackNotice: String?

    private var memoryStore: CommishMemoryStore?
    private var modelContext: ModelContext?
    private var lastSubmissionAt = Date.distantPast
    private var lastReactionFeedback: ReactionFeedbackSnapshot?
    private var hasRecordedReactionFeedback = false
    private var demoTask: Task<Void, Never>?
    private var isConfigured = false

    var modelStatus: String { intelligence.availabilityDescription }
    var hasRateableReaction: Bool {
        lastReactionFeedback != nil && !hasRecordedReactionFeedback
    }

    var reactionCorrectionOptions: [ReactionCorrectionOption] {
        guard let snapshot = lastReactionFeedback else { return [] }
        let features = Set(snapshot.featureKeys)
        if features.contains("intent:attendance"), features.contains("valence:positive") {
            return [.celebrate, .encourage, .neutral]
        }
        if features.contains("intent:health") {
            return [.disappointed, .encourage, .neutral]
        }
        return ReactionCorrectionOption.allCases
    }

    func configure(modelContext: ModelContext) {
        guard !isConfigured else { return }
        isConfigured = true
        self.modelContext = modelContext
        memoryStore = CommishMemoryStore(context: modelContext)
        DemoDataSeeder.seedIfNeeded(in: modelContext)
        memoryStore?.reconcileProfileBackedMemories()
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            inputText = ""
            UserDefaults.standard.removeObject(forKey: "PendingCommishEvent")
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                self?.inputText = ""
            }
        }
        log("Loaded canonical local fan profile")
        if let reason = commish.fallbackReason { log("Renderer fallback: \(reason)") }
        if let reason = intelligence.lastFallbackReason { log("Intelligence fallback: \(reason)") }
        consumePendingIntent()

        Task { [weak self] in
            for _ in 0..<120 {
                guard let self, !self.commish.isReady else { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
            guard let self else { return }
            self.log(self.commish.isReady ? "PNG frames decoded and ready" : "PNG renderer did not become ready")
        }
    }

    func submitCurrentEvent() async {
        await submit(eventText: inputText)
    }

    func submit(eventText: String) async {
        let cleaned = eventText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            log("Ignored an empty fan event")
            return
        }
        guard !isGenerating else {
            log("Ignored duplicate submit while a reaction was generating")
            return
        }
        guard Date().timeIntervalSince(lastSubmissionAt) > 0.4 else {
            log("Debounced a repeated submission")
            return
        }
        lastSubmissionAt = .now
        isGenerating = true
        lastReactionFeedback = nil
        hasRecordedReactionFeedback = false
        feedbackNotice = nil
        inputText = cleaned
        log("Fan event: \(cleaned)")

        let event = FanEvent(text: cleaned)
        let adjustments = memoryStore?.policyAdjustments() ?? []
        let brief = ReactionBriefBuilder.build(
            for: event,
            profile: memoryStore?.profile(),
            adjustments: adjustments
        )
        log(
            "Brief: \(brief.signals.intent.rawValue) · \(brief.topic.rawValue) · "
                + "\(brief.relationship.rawValue) · \(brief.fanImpact.rawValue)"
        )
        do {
            let reaction = try await intelligence.react(to: event, brief: brief)
            let validated = try CommishReactionValidator.validate(reaction)
            responseLine = validated.line
            currentEmotion = validated.emotion
            commish.play(validated.action)
            lastReactionFeedback = ReactionFeedbackSnapshot(
                eventText: cleaned,
                featureKeys: brief.learningFeatureKeys,
                predictedAction: validated.action,
                predictedEmotion: validated.emotion,
                providerName: intelligence.providerName,
                line: validated.line
            )
            log("\(intelligence.providerName) selected \(validated.emotion.displayName) · \(validated.action.displayName)")
            if let reason = intelligence.lastFallbackReason {
                log("Intelligence fallback: \(reason)")
            }

            if let candidate = MemoryPolicy.validatedCandidate(event: event, reaction: validated) {
                let inserted = memoryStore?.save(candidate) ?? false
                log(inserted ? "Saved durable memory: \(candidate.value)" : "Reused existing memory: \(candidate.value)")
            }
        } catch is CancellationError {
            log("Reaction generation cancelled")
        } catch {
            log("Reaction failed safely: \(error.localizedDescription)")
        }
        isGenerating = false
    }

    func approveLastReaction() {
        guard let snapshot = lastReactionFeedback, !hasRecordedReactionFeedback else { return }
        guard memoryStore?.recordReactionFeedback(snapshot, correction: nil) == true else {
            feedbackNotice = "Couldn’t save that rating."
            log("Failed to save reaction feedback")
            return
        }
        hasRecordedReactionFeedback = true
        feedbackNotice = "Saved — similar moments will lean this way."
        log("Learned positive reaction feedback on this device")
    }

    func correctLastReaction(_ correction: ReactionCorrectionOption) {
        guard let snapshot = lastReactionFeedback, !hasRecordedReactionFeedback else { return }
        guard memoryStore?.recordReactionFeedback(snapshot, correction: correction) == true else {
            feedbackNotice = "Couldn’t save that correction."
            log("Failed to save reaction correction")
            return
        }
        hasRecordedReactionFeedback = true
        currentEmotion = correction.emotion
        commish.play(correction.action)
        feedbackNotice = "Got it — \(correction.title.lowercased()) next time."
        log("Learned correction: \(correction.emotion.displayName) · \(correction.action.displayName)")
    }

    func runAnimationDemo() {
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            guard let self else { return }
            let sequence: [CommishAction] = [.idle, .wave, .pointRight, .foamFinger, .sadShrug, .idle]
            self.log("Started animation demo sequence")
            for action in sequence where !Task.isCancelled {
                self.commish.play(action)
                let definition = AnimationConfiguration.definition(for: action)
                let frames = action == .wave ? 60 : 90
                let delay = action == .idle ? 0.7 : definition.duration(frameCount: frames) + 0.2
                try? await Task.sleep(for: .seconds(delay))
            }
            if !Task.isCancelled { self.log("Animation demo sequence complete") }
        }
    }

    func runStoryDemo() {
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            guard let self else { return }
            self.log("Demo context: Penn State fan, Oregon helmets 3, streak 7")
            await self.submit(eventText: DemoScenario.all[0].event)
            try? await Task.sleep(for: .seconds(4.2))
            guard !Task.isCancelled else { return }
            await self.submit(eventText: DemoScenario.all[2].event)
            try? await Task.sleep(for: .seconds(4.2))
            guard !Task.isCancelled else { return }
            self.isMemoryPresented = true
            self.log("Opened app-owned editable memory")
        }
    }

    func resetSession() {
        intelligence.resetSession()
        log("Reset model and deterministic response sessions")
    }

    func resetDemo() {
        demoTask?.cancel()
        demoTask = nil
        commish.reset()
        intelligence.resetSession()
        responseLine = "Report the play. I’ll decide how much dignity survives."
        currentEmotion = .curious
        inputText = ""
        lastReactionFeedback = nil
        hasRecordedReactionFeedback = false
        feedbackNotice = nil
        if let modelContext { DemoDataSeeder.reset(in: modelContext) }
        logs.removeAll()
        log("Reset local demo data and character state")
    }

    func handleApplicationActive(_ isActive: Bool) {
        commish.setApplicationActive(isActive)
        if isActive { consumePendingIntent() }
    }

    func log(_ message: String) {
        logs.insert(CommishLogEntry(message: message), at: 0)
        if logs.count > 24 { logs.removeLast(logs.count - 24) }
    }

    private func consumePendingIntent() {
        let key = "PendingCommishEvent"
        guard let event = UserDefaults.standard.string(forKey: key), !event.isEmpty else { return }
        UserDefaults.standard.removeObject(forKey: key)
        inputText = event
        Task { [weak self] in await self?.submit(eventText: event) }
    }
}
