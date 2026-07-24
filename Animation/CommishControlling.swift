import SwiftUI
@preconcurrency import UIKit

@MainActor
protocol CommishControlling: AnyObject {
    var isReady: Bool { get }
    var currentAction: CommishAction { get }
    var rendererName: String { get }
    var currentFrame: UIImage? { get }
    var rendererView: AnyView? { get }
    var fallbackReason: String? { get }

    func play(_ action: CommishAction)
    func reset()
    func setApplicationActive(_ isActive: Bool)
}
