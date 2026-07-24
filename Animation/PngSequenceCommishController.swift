import Foundation
import Observation
import SwiftUI
@preconcurrency import UIKit

@MainActor
@Observable
final class PngSequenceCommishController: CommishControlling {
    private(set) var isReady = false
    private(set) var currentAction: CommishAction = .idle
    private(set) var currentFrame: UIImage?
    private(set) var fallbackReason: String?
    let rendererName = "PNG fallback"
    var rendererView: AnyView? { nil }

    @ObservationIgnored private var frames: [CommishAction: [UIImage]] = [:]
    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var isApplicationActive = true
    @ObservationIgnored private var requestedAction: CommishAction = .idle

    init(bundle: Bundle = .main) {
        Task { [weak self] in
            do {
                let loaded = try await Task.detached(priority: .userInitiated) {
                    try FramePreloader.loadAll(bundle: bundle)
                }.value
                guard let self else { return }
                self.frames = loaded
                self.isReady = true
                self.beginPlayback(self.requestedAction)
            } catch {
                self?.fallbackReason = error.localizedDescription
            }
        }
    }

    func play(_ action: CommishAction) {
        requestedAction = action
        guard isReady else { return }
        beginPlayback(action)
    }

    func reset() {
        play(.idle)
    }

    func setApplicationActive(_ isActive: Bool) {
        isApplicationActive = isActive
        if isActive {
            if isReady { beginPlayback(currentAction) }
        } else {
            playbackTask?.cancel()
            playbackTask = nil
        }
    }

    private func beginPlayback(_ action: CommishAction) {
        playbackTask?.cancel()
        playbackTask = nil
        guard let actionFrames = frames[action], !actionFrames.isEmpty else {
            fallbackReason = "Frames for \(action.displayName) are unavailable."
            return
        }
        currentAction = action
        currentFrame = actionFrames[0]
        guard isApplicationActive else { return }

        let definition = AnimationConfiguration.definition(for: action)
        playbackTask = Task { [weak self] in
            var index = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1 / definition.framesPerSecond))
                guard !Task.isCancelled, let self else { return }
                index += 1
                if index >= actionFrames.count {
                    switch definition.playbackMode {
                    case .loop:
                        index = 0
                    case .oneShotThenIdle:
                        self.beginPlayback(.idle)
                        return
                    }
                }
                self.currentFrame = actionFrames[index]
            }
        }
    }
}
