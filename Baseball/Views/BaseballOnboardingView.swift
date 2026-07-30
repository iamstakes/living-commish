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

private enum BaseballPersonalizationSheet: String, Identifiable {
    case teams
    case players
    case profile

    var id: String { rawValue }
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
            DemoAuthenticationToggle(
                isSignedIn: Binding(
                    get: { onboarding.isPersonalizedExperienceActive },
                    set: { signedIn in
                        simulateSignedInExperience(signedIn)
                    }
                )
            )
            .padding(.top, 82)
            .padding(.trailing, 28)
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

private struct BaseballOnboardingStage: View {
    let host: any AnimatedHostControlling
    let onboarding: BaseballOnboardingState
    let onChooseTeam: () -> Void
    let onChoosePlayer: () -> Void
    let onProfileTap: () -> Void
    let hostAccessibilityHint: String
    let onComplete: () -> Void

    @Environment(BaseballSearchEnvironment.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

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
                    reduceMotion: reduceMotion
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
    let onRestart: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RockiesChromeBackground()

                VStack(spacing: 18) {
                    Text("M")
                        .font(.title.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(RockiesTheme.brightPurple.gradient, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(RockiesTheme.silver.opacity(0.64), lineWidth: 1.5)
                        }

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

                    Text("Scores, standings, stories, rival watch, and the Commish’s presentation are shaped by these choices.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Button {
                        dismiss()
                        onRestart()
                    } label: {
                        Label("Personalize again", systemImage: "slider.horizontal.3")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(RockiesTheme.brightPurple)
                    .accessibilityIdentifier("profile-restart-personalization")

                    Spacer()
                }
                .padding(22)
                .padding(.top, 20)
            }
            .navigationTitle("Your profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("baseball-profile-sheet")
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
