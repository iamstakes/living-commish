import Foundation
import Observation
import RiveRuntime
import SwiftUI
@preconcurrency import UIKit

/// Owns all Rive-specific loading, schema validation, rendering, and controls.
/// The rest of the app sees only `CommishControlling`, and cannot select Rive
/// until this controller has validated the complete exported contract.
@MainActor
@Observable
final class RiveCommishController: CommishControlling {
    private(set) var isReady = false
    private(set) var currentAction: CommishAction = .idle
    private(set) var currentFrame: UIImage?
    private(set) var fallbackReason: String?
    let rendererName = "Rive"

    @ObservationIgnored private var worker: Worker?
    @ObservationIgnored private var rive: RiveRuntime.Rive?
    @ObservationIgnored private var viewModelInstance: ViewModelInstance?
    @ObservationIgnored private var completionTask: Task<Void, Never>?
    private var isApplicationActive = true

    private static let artboardName = "Commish"
    private static let stateMachineName = "CommishSM"
    private static let controls: [CommishAction: String] = [
        .pointRight: "pointRight",
        .sadShrug: "sadShrug",
        .wave: "wave",
        .foamFinger: "foamFinger",
    ]

    var rendererView: AnyView? {
        guard let rive else { return nil }
        return AnyView(
            RiveUIViewRepresentable(rive: rive)
                .paused(!isApplicationActive)
                .accessibilityLabel("Commish character, \(currentAction.displayName) animation")
        )
    }

    init(bundle: Bundle = .main) {
        guard bundle.url(forResource: "commish", withExtension: "riv") != nil else {
            fallbackReason = "commish.riv is not in the app bundle."
            return
        }
        fallbackReason = "commish.riv is being validated."
        Task { [weak self] in
            await self?.initialize(bundle: bundle)
        }
    }

    func play(_ action: CommishAction) {
        guard isReady else { return }
        completionTask?.cancel()
        completionTask = nil
        currentAction = action
        guard action != .idle else { return }
        guard
            let control = Self.controls[action],
            let viewModelInstance
        else {
            fallbackReason = "The Rive control for \(action.rawValue) became unavailable."
            return
        }

        viewModelInstance.fire(trigger: TriggerProperty(path: control))
        let definition = AnimationConfiguration.definition(for: action)
        let frameCount = action == .wave ? 60 : 90
        completionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(definition.duration(frameCount: frameCount)))
            guard !Task.isCancelled else { return }
            self?.currentAction = .idle
        }
    }

    func reset() {
        completionTask?.cancel()
        currentAction = .idle
    }

    func setApplicationActive(_ isActive: Bool) {
        isApplicationActive = isActive
    }

    private func initialize(bundle: Bundle) async {
        do {
            let worker = try await Worker()
            let file = try await RiveRuntime.File(
                source: .local("commish", bundle),
                worker: worker
            )

            let artboardNames = try await file.getArtboardNames()
            guard artboardNames.contains(Self.artboardName) else {
                throw ValidationError.missingArtboard
            }

            let artboard = try await file.createArtboard(Self.artboardName)
            let stateMachineNames = try await artboard.getStateMachineNames()
            guard stateMachineNames.contains(Self.stateMachineName) else {
                throw ValidationError.missingStateMachine
            }

            let stateMachine = try await artboard.createStateMachine(Self.stateMachineName)
            let defaultViewModel = try await file.getDefaultViewModelInfo(for: artboard)
            let properties = try await file.getProperties(of: defaultViewModel.viewModelName)
            let triggerNames = Set(properties.filter { $0.type == .trigger }.map(\.name))
            let missingControls = Set(Self.controls.values).subtracting(triggerNames)
            guard missingControls.isEmpty else {
                throw ValidationError.missingControls(missingControls.sorted())
            }

            let viewModelInstance = try await file.createViewModelInstance(
                .viewModelDefault(from: .artboardDefault(artboard))
            )
            let rive = try await RiveRuntime.Rive(
                file: file,
                artboard: artboard,
                stateMachine: stateMachine,
                dataBind: .instance(viewModelInstance),
                fit: .contain(alignment: .center)
            )

            self.worker = worker
            self.viewModelInstance = viewModelInstance
            self.rive = rive
            fallbackReason = nil
            currentAction = .idle
            isReady = true
        } catch {
            isReady = false
            fallbackReason = "Rive validation failed: \(error.localizedDescription)"
        }
    }

    private enum ValidationError: LocalizedError {
        case missingArtboard
        case missingStateMachine
        case missingControls([String])

        var errorDescription: String? {
            switch self {
            case .missingArtboard:
                "Missing Commish artboard."
            case .missingStateMachine:
                "Missing CommishSM state machine."
            case .missingControls(let names):
                "Missing Data Binding triggers: \(names.joined(separator: ", "))."
            }
        }
    }
}
