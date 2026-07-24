import SwiftData
import SwiftUI

@main
struct LivingCommishApp: App {
    @State private var environment = AppEnvironment()
    private let modelContainer: ModelContainer

    init() {
        let inMemory = ProcessInfo.processInfo.arguments.contains("--ui-testing")
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
            CommishStageView()
                .environment(environment)
                .task {
                    environment.configure(modelContext: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}
