import SwiftData
import SwiftUI

@main
struct LivingCommishApp: App {
    @State private var commishEnvironment = AppEnvironment()
    @State private var baseballEnvironment = BaseballSearchEnvironment()
    @State private var baseballOnboarding = BaseballOnboardingState()
    private let modelContainer: ModelContainer
    private let experienceMode = AppExperienceMode.resolve(
        arguments: ProcessInfo.processInfo.arguments
    )

    init() {
        let inMemory =
            ProcessInfo.processInfo.arguments.contains("--ui-testing")
            || ProcessInfo.processInfo.arguments.contains(
                "--baseball-onboarding-ui-testing"
            )
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            modelContainer = try ModelContainer(
                for: FanProfile.self,
                CommishMemory.self,
                ReactionFeedback.self,
                LearnedReactionPreference.self,
                configurations: configuration
            )
        } catch {
            fatalError("Could not create the local memory store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch experienceMode {
                case .baseballSearch:
                    BaseballExperienceRootView()
                        .environment(baseballEnvironment)
                        .environment(baseballOnboarding)
                case .livingCommish:
                    CommishStageView()
                        .environment(commishEnvironment)
                        .task {
                            commishEnvironment.configure(
                                modelContext: modelContainer.mainContext
                            )
                        }
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
