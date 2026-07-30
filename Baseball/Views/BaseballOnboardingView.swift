import SwiftUI

enum RockiesTheme {
    static var purple: Color {
        Color(red: 0.31, green: 0.14, blue: 0.48)
    }

    static var brightPurple: Color {
        Color(red: 0.51, green: 0.25, blue: 0.72)
    }

    static var midnight: Color {
        Color(red: 0.025, green: 0.025, blue: 0.055)
    }

    static var silver: Color {
        Color(red: 0.76, green: 0.78, blue: 0.83)
    }
}

private enum BaseballPersonalizationSheet: Identifiable {
    case teams
    case players
    case profile
    case collection(BaseballSticker)

    var id: String {
        switch self {
        case .teams:
            "teams"
        case .players:
            "players"
        case .profile:
            "profile"
        case .collection(let sticker):
            "collection-\(sticker.id)"
        }
    }
}

struct BaseballExperienceRootView: View {
    @Environment(BaseballSearchEnvironment.self) private var environment
    @Environment(BaseballOnboardingState.self) private var onboarding
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeSheet: BaseballPersonalizationSheet?

    var body: some View {
        Group {
            if onboarding.isPersonalizedExperienceActive {
                BaseballSearchHomeView(
                    onProfileTap: {
                        activeSheet = .profile
                    },
                    onCollectionTap: { sticker in
                        activeSheet = .collection(sticker)
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                BaseballOnboardingStage(
                    host: environment.host,
                    onboarding: onboarding,
                    onChooseTeam: {
                        activeSheet = .teams
                    },
                    onChoosePlayer: {
                        activeSheet = .players
                    },
                    onProfileTap: {
                        if onboarding.isPersonalizedExperienceActive {
                            activeSheet = .profile
                        }
                    },
                    onCollectionTap: { sticker in
                        activeSheet = .collection(sticker)
                    },
                    hostAccessibilityHint:
                        onboarding.isPersonalizedExperienceActive
                            ? "Open your baseball profile"
                            : "Choose your team and favorite player below",
                    onComplete: completePersonalization
                )
                .transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 8) {
                DemoAuthenticationToggle(
                    isSignedIn: Binding(
                        get: { onboarding.isPersonalizedExperienceActive },
                        set: { signedIn in
                            simulateSignedInExperience(signedIn)
                        }
                    )
                )

                if !environment.collectedStickers.isEmpty
                    || environment.avatarSticker != nil {
                    DemoStickerResetButton {
                        activeSheet = nil
                        environment.resetStickerDemo()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.top, 82)
            .padding(.trailing, 28)
            .animation(
                reduceMotion
                    ? nil
                    : .spring(response: 0.4, dampingFraction: 0.85),
                value: environment.collectedStickerIDs
            )
        }
        .animation(
            reduceMotion
                ? nil
                : .spring(response: 0.5, dampingFraction: 0.88),
            value: onboarding.isSignedIn
        )
        .animation(
            reduceMotion
                ? nil
                : .spring(response: 0.5, dampingFraction: 0.88),
            value: onboarding.hasCompletedOnboarding
        )
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .teams:
                BaseballTeamPickerSheet(
                    onboarding: onboarding,
                    host: environment.host
                )
            case .players:
                BaseballPlayerPickerSheet(
                    onboarding: onboarding,
                    host: environment.host
                )
            case .profile:
                BaseballProfileSheet(
                    onboarding: onboarding,
                    newlyCollectedSticker: nil,
                    onRestart: {
                        activeSheet = nil
                        onboarding.restartPersonalization()
                        environment.resetToDiscovery()
                    }
                )
            case .collection(let sticker):
                BaseballProfileSheet(
                    onboarding: onboarding,
                    newlyCollectedSticker: sticker,
                    onRestart: {
                        activeSheet = nil
                        onboarding.restartPersonalization()
                        environment.resetToDiscovery()
                    }
                )
            }
        }
        .task {
            synchronizeProfile()
            if onboarding.isPersonalizedExperienceActive,
               environment.discoveryCards.isEmpty {
                await environment.loadDiscovery()
            }
        }
        .onChange(of: onboarding.profileSnapshot) { _, _ in
            synchronizeProfile()
        }
    }

    private func simulateSignedInExperience(_ signedIn: Bool) {
        onboarding.simulatePersonalizedExperience(signedIn)
        activeSheet = nil
        environment.resetToDiscovery()
        synchronizeProfile()
        if signedIn {
            environment.host.perform(.greet)
            Task { await environment.loadDiscovery() }
        }
    }

    private func completePersonalization() {
        guard onboarding.complete() else { return }
        synchronizeProfile()
        environment.host.perform(.greet)
        Task { await environment.loadDiscovery() }
    }

    private func synchronizeProfile() {
        environment.updateProfile(onboarding.profileSnapshot)
    }
}

private struct DemoAuthenticationToggle: View {
    @Binding var isSignedIn: Bool

    var body: some View {
        Toggle(isOn: $isSignedIn) {
            Label(
                isSignedIn ? "Signed in" : "Signed out",
                systemImage: isSignedIn
                    ? "person.crop.circle.fill.badge.checkmark"
                    : "person.crop.circle.badge.xmark"
            )
            .font(.caption2.weight(.bold))
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .tint(RockiesTheme.brightPurple)
        .padding(.leading, 11)
        .padding(.trailing, 7)
        .frame(minHeight: 36)
        .glassEffect(.regular, in: Capsule())
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityLabel("Demo signed-in state")
        .accessibilityValue(isSignedIn ? "Signed in" : "Signed out")
        .accessibilityIdentifier("demo-authentication-toggle")
    }
}

private struct DemoStickerResetButton: View {
    let onReset: () -> Void

    var body: some View {
        Button(action: onReset) {
            Label("Reset rewards", systemImage: "arrow.counterclockwise")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 11)
                .frame(minHeight: 36)
        }
        .buttonStyle(.glass)
        .accessibilityHint(
            "Clears collected stickers and restores the initial avatar"
        )
        .accessibilityIdentifier("demo-reset-stickers")
    }
}

private struct BaseballOnboardingStage: View {
    let host: any AnimatedHostControlling
    let onboarding: BaseballOnboardingState
    let onChooseTeam: () -> Void
    let onChoosePlayer: () -> Void
    let onProfileTap: () -> Void
    let onCollectionTap: (BaseballSticker) -> Void
    let hostAccessibilityHint: String
    let onComplete: () -> Void

    @Environment(BaseballSearchEnvironment.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var presentedPlayerGallery: BaseballPlayerCard?

    var body: some View {
        ZStack {
            BaseballGenericChromeBackground()

            ScrollView {
                stageContent
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-onboarding")
        .onChange(of: scenePhase) { _, phase in
            environment.setApplicationActive(phase == .active)
        }
        .onAppear {
            host.perform(
                onboarding.selectedTeam == nil ? .greet : .explain
            )
        }
        .fullScreenCover(item: $presentedPlayerGallery) { player in
            BaseballPlayerGalleryExperienceView(
                player: player,
                isQuizRewardCollected: player.quiz.map {
                    environment.hasCollected($0.rewardSticker)
                } ?? false,
                onCollect: { sticker in
                    environment.collectSticker(sticker)
                },
                onOpenCollection: { sticker in
                    presentedPlayerGallery = nil
                    Task { @MainActor in
                        if !reduceMotion {
                            try? await Task.sleep(for: .milliseconds(250))
                        }
                        onCollectionTap(sticker)
                    }
                },
                onDismiss: {
                    presentedPlayerGallery = nil
                }
            )
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        switch environment.state {
        case .discovering:
            searchStage(
                accent: accent,
                thought: BaseballCommishThoughts.onboarding
            ) {
                BaseballOnboardingCard(
                    onboarding: onboarding,
                    onChooseTeam: onChooseTeam,
                    onChoosePlayer: onChoosePlayer,
                    onComplete: onComplete
                )
                .padding(.leading, 6)
                .padding(.bottom, 6)
            }
        case .interpreting(let query):
            searchStage(accent: .cyan, thought: nil) {
                SearchLoadingCard(
                    title: "Looking it up",
                    detail: query
                )
                .frame(width: 276)
                .padding(.leading, 6)
                .padding(.bottom, 64)
            }
        case .loading(let plan):
            searchStage(accent: .cyan, thought: nil) {
                SearchLoadingCard(
                    title: "Building the card",
                    detail: plan.query.entities.first?.canonicalName
                        ?? plan.query.rawText
                )
                .frame(width: 276)
                .padding(.leading, 6)
                .padding(.bottom, 64)
            }
        case .presenting(let experience):
            searchStage(accent: .cyan, thought: nil) {
                SearchResultPresentationDeck(
                    experience: experience,
                    reduceMotion: reduceMotion,
                    onOpenPlayerGallery: { player in
                        presentedPlayerGallery = player
                    }
                )
                .id(experience.query.rawText)
                .padding(.leading, 6)
                .padding(.bottom, 6)
            }
            .accessibilityIdentifier("baseball-results-stage")
        case .failed(let failure):
            searchStage(accent: .orange, thought: nil) {
                SearchFailureCard(failure: failure)
                    .frame(width: 276)
                    .padding(.leading, 6)
                    .padding(.bottom, 64)
            }
        }
    }

    private func searchStage<Content: View>(
        accent: Color,
        thought: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HostPresentationStage(
            host: host,
            accent: accent,
            thought: thought,
            onHostTap: onProfileTap,
            hostAccessibilityHint: hostAccessibilityHint,
            content: content
        )
        .overlay(alignment: .top) {
            BaseballSearchControl(
                environment: environment,
                accent: .cyan
            )
            .padding(.horizontal, 12)
            .padding(.top, 12)
        }
        .accessibilityIdentifier("baseball-onboarding-stage")
    }

    private var accent: Color {
        onboarding.step != .team
            && onboarding.selectedTeamID == BaseballTeamChoice.coloradoRockies.id
            ? RockiesTheme.brightPurple
            : .cyan
    }
}

private struct BaseballOnboardingCard: View {
    let onboarding: BaseballOnboardingState
    let onChooseTeam: () -> Void
    let onChoosePlayer: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(eyebrow)
                    .font(.caption2.weight(.black))
                    .tracking(1)
                    .foregroundStyle(accent)
                Spacer()
                Text(stepLabel)
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.title2.weight(.black))
                .fontWidth(.expanded)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: primaryAction) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(actionTitle)
                            .font(.headline.weight(.bold))
                        Text(actionDetail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    Image(systemName: actionSymbol)
                        .font(.headline.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(accent.gradient, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(actionIdentifier)
        }
        .padding(18)
        .frame(width: 276, alignment: .leading)
        .glassEffect(
            .regular.tint(accent.opacity(0.14)),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(accent.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-profile-card")
    }

    private var needsTeam: Bool {
        onboarding.step == .team
    }

    private var needsPlayer: Bool {
        onboarding.step == .player
    }

    private var accent: Color {
        needsTeam ? .cyan : RockiesTheme.brightPurple
    }

    private var eyebrow: String {
        if needsTeam { return "BUILD YOUR PROFILE" }
        if needsPlayer { return onboarding.selectedTeam?.abbreviation ?? "PLAYER" }
        return "PERSONALIZED FOR YOU"
    }

    private var stepLabel: String {
        if needsTeam { return "1 / 2" }
        if needsPlayer { return "2 / 2" }
        return "READY"
    }

    private var title: String {
        if needsTeam { return "Choose your club" }
        if needsPlayer { return "Who do you follow?" }
        return "Meet your Commish"
    }

    private var detail: String {
        if needsTeam {
            return "Pick the team you live and die with. Your Commish will build the experience around it."
        }
        if needsPlayer {
            return "Pick a favorite from the \(onboarding.selectedTeam?.fullName ?? "team") active roster."
        }
        return "\(onboarding.selectedTeam?.fullName ?? "Your club") and \(onboarding.selectedPlayer?.fullName ?? "your player") will now shape every card."
    }

    private var actionTitle: String {
        if needsTeam { return "See all 30 teams" }
        if needsPlayer { return "Open the roster" }
        return "Start my experience"
    }

    private var actionDetail: String {
        if needsTeam { return "American and National League" }
        if needsPlayer {
            return onboarding.selectedTeam?.fullName ?? "Choose a player"
        }
        return "\(onboarding.selectedTeam?.abbreviation ?? "")  •  \(onboarding.selectedPlayer?.fullName ?? "")"
    }

    private var actionSymbol: String {
        needsTeam || needsPlayer ? "arrow.up.right" : "sparkles"
    }

    private var actionIdentifier: String {
        if needsTeam { return "onboarding-team-card" }
        if needsPlayer { return "onboarding-player-card" }
        return "onboarding-finish"
    }

    private func primaryAction() {
        if needsTeam {
            onChooseTeam()
        } else if needsPlayer {
            onChoosePlayer()
        } else {
            onComplete()
        }
    }
}

private struct BaseballTeamPickerSheet: View {
    let onboarding: BaseballOnboardingState
    let host: any AnimatedHostControlling

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                    ],
                    spacing: 10
                ) {
                    ForEach(filteredTeams) { team in
                        Button {
                            onboarding.selectTeam(team)
                            host.perform(
                                team.id == BaseballTeamChoice.coloradoRockies.id
                                    ? .celebrate
                                    : .explain
                            )
                            dismiss()
                        } label: {
                            TeamChoiceTile(
                                team: team,
                                isSelected: onboarding.selectedTeamID == team.id
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(
                            onboarding.selectedTeamID == team.id
                                ? "Selected"
                                : "Not selected"
                        )
                        .accessibilityIdentifier("team-choice-\(team.id)")
                    }
                }
                .padding(16)
            }
            .background(RockiesChromeBackground())
            .navigationTitle("Choose your club")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Find an MLB team"
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("30 MLB TEAMS")
                        .font(.caption2.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("team-picker-count")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("baseball-team-picker")
    }

    private var filteredTeams: [BaseballTeamChoice] {
        let cleaned = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !cleaned.isEmpty else { return BaseballTeamChoice.all }
        return BaseballTeamChoice.all.filter {
            $0.fullName.localizedCaseInsensitiveContains(cleaned)
                || $0.abbreviation.localizedCaseInsensitiveContains(cleaned)
                || $0.division.localizedCaseInsensitiveContains(cleaned)
        }
    }
}

private struct TeamChoiceTile: View {
    let team: BaseballTeamChoice
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(team.abbreviation)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        team.id == BaseballTeamChoice.coloradoRockies.id
                            ? RockiesTheme.brightPurple.gradient
                            : Color.white.opacity(0.12).gradient,
                        in: Circle()
                    )
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            Text(team.fullName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Text(team.division.uppercased())
                .font(.system(size: 9, weight: .black))
                .tracking(0.7)
                .foregroundStyle(.secondary)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .background(
            .white.opacity(isSelected ? 0.13 : 0.065),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isSelected
                        ? RockiesTheme.silver.opacity(0.72)
                        : .white.opacity(0.08),
                    lineWidth: isSelected ? 1.5 : 1
                )
        }
    }
}

private struct BaseballPlayerPickerSheet: View {
    let onboarding: BaseballOnboardingState
    let host: any AnimatedHostControlling

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if onboarding.isLoadingRoster && onboarding.roster.isEmpty {
                    VStack(spacing: 14) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading the active roster…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let rosterError = onboarding.rosterError,
                          onboarding.roster.isEmpty {
                    ContentUnavailableView {
                        Label("Roster unavailable", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(rosterError)
                    } actions: {
                        Button("Try again") {
                            Task { await onboarding.loadRoster(force: true) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(filteredRoster) { player in
                        Button {
                            onboarding.selectPlayer(player)
                            host.perform(.celebrate)
                            dismiss()
                        } label: {
                            HStack(spacing: 13) {
                                Text(playerInitials(player.fullName))
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(
                                        RockiesTheme.brightPurple.gradient,
                                        in: Circle()
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(player.fullName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 5) {
                                        Text(player.position)
                                        if let number = player.jerseyNumber {
                                            Text("• #\(number)")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if onboarding.selectedPlayer?.id == player.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(
                            onboarding.selectedPlayer?.id == player.id
                                ? "Selected"
                                : "Not selected"
                        )
                        .accessibilityIdentifier("player-choice-\(player.id)")
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(RockiesChromeBackground())
            .navigationTitle(onboarding.selectedTeam?.name ?? "Roster")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Find a player")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("ACTIVE ROSTER")
                        .font(.caption2.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("baseball-player-picker")
        .task(id: onboarding.selectedTeamID) {
            await onboarding.loadRoster()
        }
    }

    private var filteredRoster: [BaseballPlayerChoice] {
        let cleaned = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !cleaned.isEmpty else { return onboarding.roster }
        return onboarding.roster.filter {
            $0.fullName.localizedCaseInsensitiveContains(cleaned)
                || $0.position.localizedCaseInsensitiveContains(cleaned)
        }
    }

    private func playerInitials(_ name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }
}

private struct BaseballProfileSheet: View {
    let onboarding: BaseballOnboardingState
    let newlyCollectedSticker: BaseballSticker?
    let onRestart: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(BaseballSearchEnvironment.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAvatarPromptPresented = false

    init(
        onboarding: BaseballOnboardingState,
        newlyCollectedSticker: BaseballSticker? = nil,
        onRestart: @escaping () -> Void
    ) {
        self.onboarding = onboarding
        self.newlyCollectedSticker = newlyCollectedSticker
        self.onRestart = onRestart
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RockiesChromeBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        if let newlyCollectedSticker {
                            Label(
                                collectionConfirmation(
                                    for: newlyCollectedSticker
                                ),
                                systemImage: environment.avatarSticker?.id
                                    == newlyCollectedSticker.id
                                    ? "person.crop.circle.badge.checkmark"
                                    : "checkmark.seal.fill"
                            )
                            .font(.headline.weight(.black))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier(
                                "profile-sticker-added-confirmation"
                            )

                            ProfileStickerCollectionSection(
                                stickers: environment.collectedStickers
                            )
                        }

                        ProfileAvatarView(
                            sticker: environment.avatarSticker,
                            fallbackInitial: profileInitial,
                            diameter: 76
                        )

                        VStack(spacing: 3) {
                            Text(onboarding.profileSnapshot.name)
                                .font(.title2.weight(.black))
                                .accessibilityIdentifier("profile-name")
                            Text("Baseball profile")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 10) {
                            ProfileFactRow(
                                eyebrow: "FAVORITE TEAM",
                                title: onboarding.selectedTeam?.fullName
                                    ?? "Not selected",
                                symbol: "shield.lefthalf.filled",
                                identifier: "profile-favorite-team"
                            )
                            ProfileFactRow(
                                eyebrow: "FAVORITE PLAYER",
                                title: onboarding.selectedPlayer?.fullName
                                    ?? "Not selected",
                                symbol: "figure.baseball",
                                identifier: "profile-favorite-player"
                            )
                        }

                        if newlyCollectedSticker == nil {
                            ProfileStickerCollectionSection(
                                stickers: environment.collectedStickers
                            )
                        }

                        Text("Scores, standings, stories, rival watch, and the Commish’s presentation are shaped by these choices.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Button {
                            dismiss()
                            onRestart()
                        } label: {
                            Label(
                                "Personalize again",
                                systemImage: "slider.horizontal.3"
                            )
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(RockiesTheme.brightPurple)
                        .accessibilityIdentifier(
                            "profile-restart-personalization"
                        )
                    }
                    .padding(22)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }

                if isAvatarPromptPresented,
                   let newlyCollectedSticker {
                    Color.black.opacity(0.56)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    ProfileAvatarPrompt(
                        sticker: newlyCollectedSticker,
                        onUseAvatar: {
                            environment.useStickerAsAvatar(
                                newlyCollectedSticker
                            )
                            dismissAvatarPrompt()
                        },
                        onNotNow: dismissAvatarPrompt
                    )
                    .padding(24)
                    .transition(
                        .scale(scale: 0.92).combined(with: .opacity)
                    )
                    .zIndex(1)
                }
            }
            .navigationTitle("Your profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("baseball-profile-done")
                }
            }
            .task(id: newlyCollectedSticker?.id) {
                guard let newlyCollectedSticker,
                      newlyCollectedSticker.animatedAvatarResourceName != nil,
                      environment.avatarSticker?.id
                        != newlyCollectedSticker.id else {
                    return
                }
                if !reduceMotion {
                    try? await Task.sleep(for: .milliseconds(700))
                }
                withAnimation(
                    reduceMotion
                        ? nil
                        : .spring(response: 0.45, dampingFraction: 0.86)
                ) {
                    isAvatarPromptPresented = true
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents(
            newlyCollectedSticker == nil ? [.medium, .large] : [.large]
        )
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("baseball-profile-sheet")
    }

    private var profileInitial: String {
        onboarding.profileSnapshot.name.first.map(String.init) ?? "F"
    }

    private func collectionConfirmation(
        for sticker: BaseballSticker
    ) -> String {
        if environment.avatarSticker?.id == sticker.id {
            return "\(sticker.playerName) is your avatar"
        }
        return "\(sticker.playerName) added"
    }

    private func dismissAvatarPrompt() {
        withAnimation(
            reduceMotion
                ? nil
                : .easeOut(duration: 0.22)
        ) {
            isAvatarPromptPresented = false
        }
    }
}

private struct ProfileAvatarView: View {
    let sticker: BaseballSticker?
    let fallbackInitial: String
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(RockiesTheme.brightPurple.gradient)

            if let sticker {
                AsyncImage(url: URL(string: sticker.portraitURL)) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: sticker.systemImage)
                            .font(
                                .system(
                                    size: diameter * 0.42,
                                    weight: .black
                                )
                            )
                            .foregroundStyle(.white)
                    }
                }
                .clipShape(Circle())
            } else {
                Text(fallbackInitial)
                    .font(.system(size: diameter * 0.42, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: diameter, height: diameter)
        .overlay {
            Circle()
                .stroke(
                    sticker == nil
                        ? AnyShapeStyle(
                            RockiesTheme.silver.opacity(0.64)
                        )
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [.white, .cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ),
                    lineWidth: sticker == nil ? 1.5 : 3
                )
        }
        .shadow(
            color: sticker == nil
                ? .clear
                : RockiesTheme.brightPurple.opacity(0.46),
            radius: 16,
            y: 8
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            sticker.map {
                "\($0.playerName) sticker profile avatar"
            } ?? "\(fallbackInitial) profile avatar"
        )
        .accessibilityIdentifier(
            sticker.map {
                "profile-avatar-\($0.id)"
            } ?? "profile-avatar-initial"
        )
    }
}

private struct ProfileAvatarPrompt: View {
    let sticker: BaseballSticker
    let onUseAvatar: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ProfileAvatarView(
                sticker: sticker,
                fallbackInitial: "",
                diameter: 104
            )

            VStack(spacing: 7) {
                Text("Change your avatar?")
                    .font(.title2.weight(.black))

                Text(
                    "Use your new \(sticker.playerName) sticker as your profile avatar?"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onUseAvatar) {
                Label(
                    "Use as my avatar",
                    systemImage: "person.crop.circle.badge.checkmark"
                )
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.glassProminent)
            .tint(RockiesTheme.brightPurple)
            .accessibilityIdentifier("avatar-prompt-use-sticker")

            Button("Not now", action: onNotNow)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("avatar-prompt-not-now")
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.46), radius: 36, y: 18)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("avatar-sticker-prompt")
    }
}

private struct ProfileStickerCollectionSection: View {
    let stickers: [BaseballSticker]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("STICKER COLLECTION", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 10, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(.cyan)

                Spacer()

                Text("\(stickers.count) / \(BaseballStickerCatalog.all.count)")
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(.secondary)
            }

            if stickers.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                        .font(.title2)
                        .foregroundStyle(RockiesTheme.silver)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Your collection starts here")
                            .font(.subheadline.weight(.black))
                        Text("Complete a baseball quiz to earn your first player card.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    .white.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .accessibilityIdentifier("profile-sticker-empty-state")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(stickers) { sticker in
                            BaseballStickerCardView(
                                sticker: sticker,
                                size: .compact
                            )
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(15)
        .background(
            .white.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("profile-sticker-collection")
    }
}

private struct ProfileFactRow: View {
    let eyebrow: String
    let title: String
    let symbol: String
    let identifier: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(RockiesTheme.silver)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow)
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
            }
            Spacer()
        }
        .padding(14)
        .background(
            .white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

struct RockiesChromeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.018, green: 0.026, blue: 0.052),
                    Color(red: 0.115, green: 0.045, blue: 0.17),
                    RockiesTheme.midnight,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(RockiesTheme.brightPurple.opacity(0.22))
                .frame(width: 360, height: 360)
                .blur(radius: 82)
                .offset(x: 170, y: -290)

            RockiesPinstripes(opacity: 0.075, spacing: 22)

            RockiesMountainRange()
                .fill(RockiesTheme.purple.opacity(0.18))
                .frame(height: 260)
                .offset(y: 140)
                .frame(maxHeight: .infinity, alignment: .bottom)

            RockiesMountainRange()
                .stroke(
                    RockiesTheme.silver.opacity(0.12),
                    style: StrokeStyle(lineWidth: 1, lineJoin: .round)
                )
                .frame(height: 225)
                .offset(x: 28, y: 130)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rockies purple pinstripe and mountain theme")
        .accessibilityIdentifier("rockies-chrome-background")
    }
}

struct BaseballGenericChromeBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.018, green: 0.035, blue: 0.07),
                        Color(red: 0.025, green: 0.075, blue: 0.095),
                        Color(red: 0.035, green: 0.025, blue: 0.06),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.blue.opacity(0.18))
                    .frame(width: 350, height: 350)
                    .blur(radius: 86)
                    .offset(x: 170, y: -280)

                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 92)
                    .offset(x: -190, y: 310)

                Image(systemName: "baseball.fill")
                    .font(.system(size: 280, weight: .thin))
                    .foregroundStyle(.white.opacity(0.025))
                    .rotationEffect(.degrees(-18))
                    .offset(x: 135, y: -180)
                    .accessibilityHidden(true)

                BaseballDiamondOutline()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.02),
                                .cyan.opacity(0.10),
                                .white.opacity(0.025),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(
                            lineWidth: 1.2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 430, height: 430)
                    .offset(y: 250)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generic Major League Baseball theme")
        .accessibilityIdentifier("baseball-generic-chrome-background")
    }
}

private struct BaseballDiamondOutline: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let top = CGPoint(x: center.x, y: rect.minY + rect.height * 0.12)
            let right = CGPoint(x: rect.maxX - rect.width * 0.12, y: center.y)
            let bottom = CGPoint(x: center.x, y: rect.maxY - rect.height * 0.12)
            let left = CGPoint(x: rect.minX + rect.width * 0.12, y: center.y)

            path.move(to: top)
            path.addLine(to: right)
            path.addLine(to: bottom)
            path.addLine(to: left)
            path.closeSubpath()

            path.move(to: bottom)
            path.addQuadCurve(
                to: top,
                control: CGPoint(x: rect.midX, y: rect.midY)
            )
        }
    }
}

private struct RockiesPinstripes: View {
    let opacity: Double
    let spacing: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()
            for x in stride(from: 0, through: size.width, by: spacing) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(
                path,
                with: .color(RockiesTheme.silver.opacity(opacity)),
                lineWidth: 0.7
            )
        }
    }
}

private struct RockiesMountainRange: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(
                to: CGPoint(x: rect.minX, y: rect.maxY * 0.76)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.17, y: rect.maxY * 0.46)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.28, y: rect.maxY * 0.68)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.48, y: rect.maxY * 0.22)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.62, y: rect.maxY * 0.56)
            )
            path.addLine(
                to: CGPoint(x: rect.width * 0.76, y: rect.maxY * 0.36)
            )
            path.addLine(
                to: CGPoint(x: rect.maxX, y: rect.maxY * 0.74)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
