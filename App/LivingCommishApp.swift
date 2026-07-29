import SwiftUI

@main
struct LivingCommishApp: App {
    @State private var baseballEnvironment = BaseballSearchEnvironment()
    @State private var baseballOnboarding = BaseballOnboardingState()

    var body: some Scene {
        WindowGroup {
            BaseballExperienceRootView()
                .environment(baseballEnvironment)
                .environment(baseballOnboarding)
        }
    }
}
