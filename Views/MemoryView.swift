import SwiftData
import SwiftUI

struct MemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment
    @Query(sort: \CommishMemory.lastUsedAt, order: .reverse) private var memories: [CommishMemory]
    @Query private var profiles: [FanProfile]
    @Query(sort: \ReactionFeedback.createdAt, order: .reverse) private var reactionFeedback: [ReactionFeedback]
    @Query private var learnedPreferences: [LearnedReactionPreference]
    @State private var confirmForget = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Stored by Living Commish on this device", systemImage: "lock.iphone")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Demo fan profile") {
                    if let profile = profiles.first {
                        FanProfileEditor(profile: profile)
                    } else {
                        ContentUnavailableView("No fan profile", systemImage: "person.crop.circle.badge.xmark")
                    }
                }

                Section("Durable memories") {
                    if memories.isEmpty {
                        Text("No memories saved.").foregroundStyle(.secondary)
                    }
                    ForEach(memories) { memory in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(memory.value).font(.body.weight(.medium))
                            Text(memory.category).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { memories[$0] }.forEach(modelContext.delete)
                        try? modelContext.save()
                    }
                }

                Section("Learned reaction policy") {
                    LabeledContent("Explicit ratings", value: "\(reactionFeedback.count)")
                    LabeledContent("Learned signals", value: "\(learnedSignalCount)")
                    Text(
                        reactionFeedback.isEmpty
                            ? "Rate a reaction to start personalizing gestures and emotions."
                            : "Your ratings tune future gestures and emotions for similar situations."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    Label("Learning stays on this device and can be erased below.", systemImage: "lock.iphone")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Restore Demo Data", systemImage: "arrow.counterclockwise") {
                        DemoDataSeeder.reset(in: modelContext)
                        environment.log("Restored seeded demo memory")
                    }
                    Button("Forget Everything", systemImage: "trash", role: .destructive) {
                        confirmForget = true
                    }
                    .accessibilityIdentifier("forget-everything-button")
                }
            }
            .navigationTitle("Fan Memory")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Forget all local fan memory?", isPresented: $confirmForget, titleVisibility: .visible) {
                Button("Forget Everything", role: .destructive) {
                    CommishMemoryStore(context: modelContext).forgetEverything()
                    environment.log("Forgot all app-owned fan memory")
                }
            } message: {
                Text("This removes the fan profile, saved memories, ratings, and learned reaction policy from this device.")
            }
        }
    }

    private var learnedSignalCount: Int {
        Set(learnedPreferences.map(\.featureKey)).count
    }
}

private struct FanProfileEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: FanProfile

    var body: some View {
        LabeledContent("Favorite team") { TextField("Team", text: favoriteTeam).multilineTextAlignment(.trailing) }
        LabeledContent("Rival team") { TextField("Team", text: rivalTeam).multilineTextAlignment(.trailing) }
        LabeledContent("Tone") { TextField("Tone", text: preferredTone).multilineTextAlignment(.trailing) }
        LabeledContent("Current streak", value: "\(profile.currentStreak)")
        LabeledContent("Oregon helmets", value: "\(profile.oregonHelmetsCracked)")
        LabeledContent("Ohio State helmets", value: "\(profile.ohioStateHelmetsCracked)")
        if profile.isDemoData {
            Label("Seeded demo data", systemImage: "testtube.2")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    private var favoriteTeam: Binding<String> {
        Binding(
            get: { profile.favoriteTeam },
            set: {
                profile.favoriteTeam = $0
                markEdited()
            }
        )
    }

    private var rivalTeam: Binding<String> {
        Binding(
            get: { profile.rivalTeam },
            set: {
                profile.rivalTeam = $0
                markEdited()
            }
        )
    }

    private var preferredTone: Binding<String> {
        Binding(
            get: { profile.preferredCommishTone },
            set: {
                profile.preferredCommishTone = $0
                markEdited()
            }
        )
    }

    private func markEdited() {
        profile.isDemoData = false
        profile.updatedAt = .now
        try? modelContext.save()
    }
}
