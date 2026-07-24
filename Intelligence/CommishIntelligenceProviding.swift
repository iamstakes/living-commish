import Foundation

@MainActor
protocol CommishIntelligenceProviding: AnyObject {
    var providerName: String { get }
    var isAvailable: Bool { get }
    var availabilityDescription: String { get }

    func react(to event: FanEvent, brief: ReactionBrief) async throws -> CommishReaction
    func resetSession()
}
