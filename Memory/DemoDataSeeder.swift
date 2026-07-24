import SwiftData

@MainActor
enum DemoDataSeeder {
    static func seedIfNeeded(in context: ModelContext) {
        let profiles = (try? context.fetch(FetchDescriptor<FanProfile>())) ?? []
        guard profiles.isEmpty else { return }

        context.insert(FanProfile(
            favoriteTeam: "Penn State",
            rivalTeam: "Ohio State",
            preferredCommishTone: "playful",
            currentStreak: 7,
            oregonHelmetsCracked: 3,
            ohioStateHelmetsCracked: 1,
            isDemoData: true
        ))
        try? context.save()
    }

    static func reset(in context: ModelContext) {
        CommishMemoryStore(context: context).forgetEverything()
        seedIfNeeded(in: context)
    }
}
