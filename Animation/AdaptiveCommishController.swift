import Foundation
import Observation
import SwiftUI
@preconcurrency import UIKit

@MainActor
@Observable
final class AdaptiveCommishController: CommishControlling {
    private let pngController: PngSequenceCommishController
    private let riveController: RiveCommishController

    init(bundle: Bundle = .main) {
        pngController = PngSequenceCommishController(bundle: bundle)
        riveController = RiveCommishController(bundle: bundle)
    }

    private var activeController: any CommishControlling {
        riveController.isReady ? riveController : pngController
    }

    var isReady: Bool { activeController.isReady }
    var currentAction: CommishAction { activeController.currentAction }
    var rendererName: String { activeController.rendererName }
    var currentFrame: UIImage? { activeController.currentFrame }
    var rendererView: AnyView? { activeController.rendererView }
    var fallbackReason: String? { riveController.isReady ? nil : riveController.fallbackReason }

    func play(_ action: CommishAction) {
        activeController.play(action)
    }

    func reset() {
        activeController.reset()
    }

    func setApplicationActive(_ isActive: Bool) {
        activeController.setApplicationActive(isActive)
    }
}
