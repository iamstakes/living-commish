import SwiftUI

@main
struct CollegeFootballCommishApp: App {
    @State private var collegeFootballEnvironment = CollegeFootballSearchEnvironment()
    @State private var collegeFootballOnboarding = CollegeFootballOnboardingState()

    var body: some Scene {
        WindowGroup {
            CollegeFootballExperienceRootView()
                .environment(collegeFootballEnvironment)
                .environment(collegeFootballOnboarding)
        }
    }
}
