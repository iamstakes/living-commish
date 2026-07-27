import Foundation
import Observation
import SwiftUI
@preconcurrency import UIKit

enum HostBehavior: String, CaseIterable, Hashable, Identifiable, Sendable {
    case idle
    case greet
    case think
    case celebrate
    case explain
    case concerned
    case tease
    case interrupt

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .idle: "Idle"
        case .greet: "Greeting"
        case .think: "Thinking"
        case .celebrate: "Celebrating"
        case .explain: "Explaining"
        case .concerned: "Concerned"
        case .tease: "Teasing"
        case .interrupt: "Breaking In"
        }
    }
}

struct AnimatedHostDescriptor: Equatable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let accessibilityName: String
    let personaInstructions: String
    let disclosure: String
    let supportedBehaviors: Set<HostBehavior>
    let fallbackBehaviors: [HostBehavior: HostBehavior]

    func resolvedBehavior(for requestedBehavior: HostBehavior) -> HostBehavior {
        if supportedBehaviors.contains(requestedBehavior) {
            return requestedBehavior
        }
        if let fallback = fallbackBehaviors[requestedBehavior],
           supportedBehaviors.contains(fallback) {
            return fallback
        }
        return supportedBehaviors.contains(.idle) ? .idle : supportedBehaviors.first ?? .idle
    }

    static let legacyCommish = AnimatedHostDescriptor(
        id: "living-commish",
        displayName: "Living Commish",
        accessibilityName: "Living Commish animated baseball guide",
        personaInstructions: """
        A fictional animated league host with dry wit, emotional range, and excellent timing.
        The host explains supplied baseball context without inventing facts or speaking for a real person.
        """,
        disclosure: "Living Commish is a fictional animated guide.",
        supportedBehaviors: Set(HostBehavior.allCases),
        fallbackBehaviors: [
            .think: .idle,
            .tease: .explain,
            .interrupt: .explain,
        ]
    )
}

enum HostRenderedContent {
    case nativeView(AnyView)
    case imageFrame(UIImage)
    case unavailable
}

@MainActor
protocol AnimatedHostControlling: AnyObject {
    var descriptor: AnimatedHostDescriptor { get }
    var isReady: Bool { get }
    var currentBehavior: HostBehavior { get }
    var rendererName: String { get }
    var renderedContent: HostRenderedContent { get }
    var fallbackReason: String? { get }

    func perform(_ behavior: HostBehavior)
    func reset()
    func setApplicationActive(_ isActive: Bool)
}

@MainActor
@Observable
final class LegacyCommishHostAdapter: AnimatedHostControlling {
    let descriptor = AnimatedHostDescriptor.legacyCommish
    @ObservationIgnored private let controller: any CommishControlling

    init(controller: any CommishControlling) {
        self.controller = controller
    }

    convenience init(bundle: Bundle = .main) {
        self.init(controller: AdaptiveCommishController(bundle: bundle))
    }

    var isReady: Bool { controller.isReady }
    var rendererName: String { controller.rendererName }
    var fallbackReason: String? { controller.fallbackReason }

    var currentBehavior: HostBehavior {
        switch controller.currentAction {
        case .idle: .idle
        case .wave: .greet
        case .foamFinger: .celebrate
        case .sadShrug: .concerned
        case .pointRight: .explain
        }
    }

    var renderedContent: HostRenderedContent {
        if let rendererView = controller.rendererView {
            return .nativeView(rendererView)
        }
        if let frame = controller.currentFrame {
            return .imageFrame(frame)
        }
        return .unavailable
    }

    func perform(_ behavior: HostBehavior) {
        controller.play(action(for: descriptor.resolvedBehavior(for: behavior)))
    }

    func reset() {
        controller.reset()
    }

    func setApplicationActive(_ isActive: Bool) {
        controller.setApplicationActive(isActive)
    }

    private func action(for behavior: HostBehavior) -> CommishAction {
        switch behavior {
        case .idle, .think:
            .idle
        case .greet:
            .wave
        case .celebrate:
            .foamFinger
        case .explain, .tease, .interrupt:
            .pointRight
        case .concerned:
            .sadShrug
        }
    }
}
