import Foundation
import Observation

@MainActor
@Observable
final class AdaptiveCommishIntelligenceProvider: CommishIntelligenceProviding {
    private let apple = AppleFoundationModelsCommishProvider()
    private let deterministic = DeterministicCommishProvider()
    private let forceLocalFallback: Bool

    private(set) var providerName: String
    private(set) var lastFallbackReason: String?
    private(set) var fallbackNotice: String?

    init(forceLocalFallback: Bool = false) {
        self.forceLocalFallback = forceLocalFallback
        providerName = !forceLocalFallback && apple.isAvailable ? apple.providerName : deterministic.providerName
        if forceLocalFallback {
            lastFallbackReason = "Local fallback was explicitly selected."
            fallbackNotice = "Personalized local intelligence is active."
        } else if !apple.isAvailable {
            lastFallbackReason = apple.availabilityDescription
            fallbackNotice = "Apple Intelligence is unavailable; personalized local intelligence is active."
        }
    }

    var isAvailable: Bool { true }
    var appleModelIsAvailable: Bool { apple.isAvailable }
    var availabilityDescription: String { apple.availabilityDescription }

    func react(to event: FanEvent, brief: ReactionBrief) async throws -> CommishReaction {
        if apple.isAvailable && !forceLocalFallback {
            var errors: [String] = []
            for attempt in 1...2 {
                do {
                    let generated = try await apple.react(to: event, brief: brief)
                    providerName = apple.providerName
                    lastFallbackReason = nil
                    fallbackNotice = nil
                    return generated
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    errors.append(error.localizedDescription)
                    if attempt == 1 { apple.resetSession() }
                }
            }
            lastFallbackReason = "Apple generation failed twice: \(errors.joined(separator: " | "))"
            fallbackNotice = "Apple generation failed after one retry; personalized local intelligence is active."
        } else if forceLocalFallback {
            lastFallbackReason = "Local fallback was explicitly selected."
            fallbackNotice = "Personalized local intelligence is active."
        } else {
            lastFallbackReason = apple.availabilityDescription
            fallbackNotice = "Apple Intelligence is unavailable; personalized local intelligence is active."
        }

        providerName = deterministic.providerName
        let local = try await deterministic.react(to: event, brief: brief)
        return try CommishReactionValidator.validate(local)
    }

    func resetSession() {
        apple.resetSession()
        deterministic.resetSession()
        providerName = !forceLocalFallback && apple.isAvailable ? apple.providerName : deterministic.providerName
        if !forceLocalFallback && apple.isAvailable {
            lastFallbackReason = nil
            fallbackNotice = nil
        }
    }
}
