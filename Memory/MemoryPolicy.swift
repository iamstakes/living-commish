import Foundation

enum MemoryPolicy {
    private static let sensitiveTerms = [
        "address", "phone", "email", "religion", "race", "ethnicity",
        "medical", "diagnosis", "political", "sexual", "gender identity"
    ]

    static func validatedCandidate(
        event: FanEvent,
        reaction: CommishReaction
    ) -> MemoryCandidate? {
        guard reaction.memoryDecision != .none,
              let rawValue = reaction.memoryValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              (2...40).contains(rawValue.count) else { return nil }

        let eventText = event.text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let value = rawValue.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        guard eventText.contains(value),
              !sensitiveTerms.contains(where: eventText.contains) else { return nil }

        switch reaction.memoryDecision {
        case .favoriteTeam, .rivalTeam, .preferredTone, .recurringInterest:
            return MemoryCandidate(category: reaction.memoryDecision, value: rawValue, confidence: 1)
        case .none:
            return nil
        }
    }
}
