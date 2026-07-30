import SwiftUI

struct BaseballSearchHomeView: View {
    var onProfileTap: () -> Void = {}
    var onCollectionTap: (BaseballSticker) -> Void = { _ in }

    @Environment(BaseballSearchEnvironment.self) private var environment
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @State private var presentedDailyDrop: BaseballDailyDrop?
    @State private var presentedPlayerGallery: BaseballPlayerCard?

    var body: some View {
        @Bindable var environment = environment

        ZStack {
            RockiesChromeBackground()

            ScrollView {
                VStack(spacing: 24) {
                    stateContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(.dark)
        .task {
            if environment.discoveryCards.isEmpty {
                await environment.loadDiscovery()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            environment.setApplicationActive(phase == .active)
        }
        .animation(
            reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.86),
            value: stateAnimationKey
        )
        .fullScreenCover(item: $presentedDailyDrop) { drop in
            BaseballDailyDropFullScreenView(
                drop: drop,
                isAlreadyCollected: environment.hasCollected(
                    drop.rewardSticker
                ),
                onCollect: { sticker in
                    environment.collectSticker(sticker)
                },
                onOpenCollection: {
                    presentedDailyDrop = nil
                    Task { @MainActor in
                        if !reduceMotion {
                            try? await Task.sleep(for: .milliseconds(250))
                        }
                        onCollectionTap(drop.rewardSticker)
                    }
                },
                onDismiss: {
                    presentedDailyDrop = nil
                }
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
    private var stateContent: some View {
        switch environment.state {
        case .discovering:
            discoverySection
        case .interpreting(let query):
            integratedSearchStage(accent: .purple, thought: nil) {
                SearchLoadingCard(
                    title: "Looking it up",
                    detail: query
                )
                .frame(width: 276)
                .padding(.leading, 6)
                .padding(.bottom, 64)
            }
        case .loading(let plan):
            integratedSearchStage(accent: .cyan, thought: nil) {
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
            resultsSection(experience)
        case .failed(let failure):
            integratedSearchStage(accent: .orange, thought: nil) {
                SearchFailureCard(failure: failure)
                    .frame(width: 276)
                    .padding(.leading, 6)
                    .padding(.bottom, 64)
            }
        }
    }

    private var discoverySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let activeDiscoveryCard {
                integratedSearchStage(
                    accent: discoveryAccent(for: activeDiscoveryCardIndex),
                    thought: activeDiscoveryCard.hostThought
                ) {
                    DiscoveryPresentationDeck(
                        card: activeDiscoveryCard,
                        accent: discoveryAccent(for: activeDiscoveryCardIndex),
                        position: activeDiscoveryCardIndex + 1,
                        count: environment.discoveryCards.count,
                        reduceMotion: reduceMotion,
                        isDailyDropCollected: activeDiscoveryCard.dailyDrop.map {
                            environment.hasCollected($0.rewardSticker)
                        } ?? false,
                        onPrevious: {
                            environment.moveDiscoveryCard(by: -1)
                        },
                        onNext: {
                            environment.moveDiscoveryCard(by: 1)
                        },
                        onOpen: {
                            if let dailyDrop = activeDiscoveryCard.dailyDrop {
                                presentedDailyDrop = dailyDrop
                            } else if let playerStory = activeDiscoveryCard.playerStory {
                                openURL(playerStory.sourceURL)
                            } else {
                                runSearch(activeDiscoveryCard.destinationQuery)
                            }
                        }
                    )
                    .padding(.leading, 6)
                    .padding(.bottom, 6)
                }
                .accessibilityIdentifier("discovery-presentation-stage")
            } else {
                HStack(spacing: 12) {
                    ProgressView()
                    Text(environment.discoveryError ?? "Finding what matters now…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 130)
                .glassEffect(
                    .clear,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-discovery-section")
    }

    private var activeDiscoveryCard: BaseballDiscoveryCard? {
        environment.discoveryCards.first {
            $0.id == environment.activeDiscoveryCardID
        } ?? environment.discoveryCards.first
    }

    private func integratedSearchStage<Content: View>(
        accent: Color,
        thought: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HostPresentationStage(
            host: environment.host,
            accent: accent,
            thought: thought,
            onHostTap: onProfileTap,
            content: content
        )
        .overlay(alignment: .top) {
            BaseballSearchControl(
                environment: environment,
                accent: RockiesTheme.brightPurple
            )
                .padding(.horizontal, 12)
                .padding(.top, 12)
        }
        .accessibilityIdentifier("search-presentation-stage")
    }

    private func resultsSection(
        _ experience: BaseballSearchExperience
    ) -> some View {
        let accent = experience.modules
            .first(where: \.isPreviewModule)?
            .featuredContent.accent
            ?? RockiesTheme.brightPurple

        return integratedSearchStage(accent: accent, thought: nil) {
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
    }

    private var activeDiscoveryCardIndex: Int {
        guard let activeDiscoveryCard else { return 0 }
        return environment.discoveryCards.firstIndex {
            $0.id == activeDiscoveryCard.id
        } ?? 0
    }

    private var stateAnimationKey: String {
        switch environment.state {
        case .discovering: "discovering"
        case .interpreting: "interpreting"
        case .loading: "loading"
        case .presenting: "presenting"
        case .failed: "failed"
        }
    }

    private func discoveryAccent(for index: Int) -> Color {
        [
            RockiesTheme.brightPurple,
            .cyan,
            RockiesTheme.silver,
            .purple,
            .mint,
        ][index % 5]
    }

    private func runSearch(_ query: String) {
        Task { await environment.search(query) }
    }
}

struct BaseballSearchControl: View {
    @Bindable var environment: BaseballSearchEnvironment
    let accent: Color

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextField(
                        "Ask me anything MLB!",
                        text: $environment.searchText
                    )
                    .font(.body.weight(.medium))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onSubmit(submitSearch)
                    .accessibilityLabel("Search")
                    .accessibilityIdentifier("baseball-search-field")

                    if !environment.searchText.isEmpty {
                        Button(action: clearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search and return")
                        .accessibilityIdentifier("clear-baseball-search")
                    }
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 58)
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )

                Button(action: submitSearch) {
                    Group {
                        if environment.isSearching {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up.right")
                                .font(.headline.bold())
                        }
                    }
                    .frame(width: 25, height: 25)
                }
                .buttonStyle(.glassProminent)
                .tint(accent)
                .disabled(
                    environment.isSearching
                        || environment.searchText
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                )
                .accessibilityLabel("Run baseball search")
                .accessibilityIdentifier("baseball-search-button")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-search-section")
        .onChange(of: environment.searchText) { oldValue, newValue in
            guard !oldValue.isEmpty,
                  newValue.isEmpty,
                  !environment.isSearching else {
                return
            }
            environment.resetToDiscovery()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    isSearchFocused = false
                } label: {
                    Label("Done", systemImage: "keyboard.chevron.compact.down")
                }
                .accessibilityLabel("Dismiss search keyboard")
                .accessibilityIdentifier("dismiss-search-keyboard")
            }
        }
    }

    private func submitSearch() {
        let query = environment.searchText
        isSearchFocused = false
        Task { await environment.search(query) }
    }

    private func clearSearch() {
        isSearchFocused = false
        environment.searchText = ""
    }
}

private enum BaseballHostStageLayout {
    static let height: CGFloat = 770
    static let hostHeight: CGFloat = 490
    static let hostScale: CGFloat = 1.70
    static let hostXOffsetFraction: CGFloat = 0.15
    static let hostYOffset: CGFloat = 160
    static let hostAlignment: Alignment = .topTrailing
    static let contentAlignment: Alignment = .bottomLeading
    static let badgeAlignment: Alignment = .topLeading
    static let badgeTopPadding: CGFloat = 88
    static let thoughtTopPadding: CGFloat = 160
    static let thoughtLeadingPadding: CGFloat = 14
    static let thoughtHeight: CGFloat = 300
    static let thoughtWidthFraction: CGFloat = 0.43
    static let thoughtMaximumWidth: CGFloat = 150
}

struct HostPresentationStage<Content: View>: View {
    let host: any AnimatedHostControlling
    let accent: Color
    let thought: String?
    let onHostTap: () -> Void
    let hostAccessibilityHint: String
    private let content: Content

    @Environment(BaseballSearchEnvironment.self) private var environment

    init(
        host: any AnimatedHostControlling,
        accent: Color,
        thought: String? = nil,
        onHostTap: @escaping () -> Void = {},
        hostAccessibilityHint: String = "Open your baseball profile",
        @ViewBuilder content: () -> Content
    ) {
        self.host = host
        self.accent = accent
        self.thought = thought
        self.onHostTap = onHostTap
        self.hostAccessibilityHint = hostAccessibilityHint
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.12),
                                Color.blue.opacity(0.05),
                                .clear,
                            ],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(.white.opacity(0.06), lineWidth: 1)
                    }

                AnimatedHostView(
                    host: host,
                    height: BaseballHostStageLayout.hostHeight,
                    accent: accent,
                    contentScale: BaseballHostStageLayout.hostScale,
                    contentOffset: CGSize(width: -8, height: 2),
                    selectedAvatar: environment.avatarSticker
                )
                .frame(width: proxy.size.width * 0.90)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: BaseballHostStageLayout.hostAlignment
                )
                .offset(
                    x: proxy.size.width
                        * BaseballHostStageLayout.hostXOffsetFraction,
                    y: BaseballHostStageLayout.hostYOffset
                )
                .contentShape(Rectangle())
                .onTapGesture(perform: onHostTap)
                .accessibilityHint(hostAccessibilityHint)
                .zIndex(1)

                if let thought,
                   !thought.trimmingCharacters(
                       in: .whitespacesAndNewlines
                   ).isEmpty {
                    CommishLiveThoughtView(
                        message: thought,
                        accent: accent
                    )
                    .frame(
                        width: min(
                            proxy.size.width
                                * BaseballHostStageLayout.thoughtWidthFraction,
                            BaseballHostStageLayout.thoughtMaximumWidth
                        ),
                        height: BaseballHostStageLayout.thoughtHeight,
                        alignment: .bottomLeading
                    )
                    .padding(
                        .leading,
                        BaseballHostStageLayout.thoughtLeadingPadding
                    )
                    .padding(
                        .top,
                        BaseballHostStageLayout.thoughtTopPadding
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .allowsHitTesting(false)
                    .zIndex(2)
                }

                content
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: BaseballHostStageLayout.contentAlignment
                    )
                    .zIndex(2)

                HostReadyBadge(host: host)
                    .padding(.top, BaseballHostStageLayout.badgeTopPadding)
                    .padding(.horizontal, 12)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: BaseballHostStageLayout.badgeAlignment
                    )
                    .zIndex(3)
            }
        }
        .frame(height: BaseballHostStageLayout.height)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("host-presentation-stage")
    }
}

private struct CommishLiveThoughtView: View {
    let message: String
    let accent: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleText = ""
    @State private var isTyping = false

    var body: some View {
        Text(displayText)
            .font(
                .system(
                    size: 16,
                    weight: .semibold,
                    design: .rounded
                )
            )
            .lineSpacing(3)
            .multilineTextAlignment(.leading)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, accent.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black.opacity(0.65), radius: 4, y: 2)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottomLeading
            )
            .task(id: "\(reduceMotion)-\(message)") {
                await animateThought()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Commish says: \(message)")
            .accessibilityIdentifier("commish-live-thought")
    }

    private var displayText: String {
        if reduceMotion {
            return message
        }
        return visibleText + (isTyping ? "▌" : "")
    }

    private func animateThought() async {
        visibleText = ""
        isTyping = false

        guard !reduceMotion else { return }

        do {
            isTyping = true
            for character in message {
                try Task.checkCancellation()
                visibleText.append(character)
                try await Task.sleep(for: .milliseconds(22))
            }
            isTyping = false
        } catch is CancellationError {
            isTyping = false
        } catch {
            isTyping = false
        }
    }
}

private struct HostReadyBadge: View {
    let host: any AnimatedHostControlling

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(host.isReady ? .green : .orange)
                .frame(width: 7, height: 7)
            Text(host.isReady ? "Ready" : "Warming up")
                .font(.caption2.weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassEffect(.clear, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            host.isReady
                ? "\(host.descriptor.accessibilityName) is ready"
                : "\(host.descriptor.accessibilityName) is warming up"
        )
    }
}

private struct DiscoveryPresentationDeck: View {
    private let cardScale: CGFloat = 1.14

    let card: BaseballDiscoveryCard
    let accent: Color
    let position: Int
    let count: Int
    let reduceMotion: Bool
    let isDailyDropCollected: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(accent.opacity(0.08))
                    .frame(width: 249, height: 234)
                    .offset(x: -14, y: 14)
                    .rotationEffect(.degrees(-2))

                Button(action: onOpen) {
                    Group {
                        if let dailyDrop = card.dailyDrop {
                            BaseballDailyDropDiscoveryCardContent(
                                drop: dailyDrop,
                                isCollected: isDailyDropCollected
                            )
                        } else if let finalScore = card.finalScore {
                            FinalScoreDiscoveryCardContent(score: finalScore)
                        } else if let standings = card.standings {
                            DynamicStandingsDiscoveryCardContent(
                                standings: standings,
                                reduceMotion: reduceMotion
                            )
                        } else if let playerStory = card.playerStory {
                            PlayerStoryDiscoveryCardContent(story: playerStory)
                        } else {
                            VStack(alignment: .leading, spacing: 11) {
                                HStack {
                                    Image(systemName: card.systemImage)
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(accent)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 0)

                                Text(card.eyebrow)
                                    .font(.caption2.weight(.black))
                                    .tracking(1)
                                    .foregroundStyle(accent)
                                Text(card.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(3)
                                Text(card.whyItMatters)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(3)
                            }
                            .padding(17)
                            .frame(width: 230, height: 215, alignment: .leading)
                            .glassEffect(
                                .regular.tint(accent.opacity(0.16)).interactive(),
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                            )
                        }
                    }
                    .scaleEffect(cardScale)
                    .frame(width: 264, height: 247)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(accessibilityHint)
                .accessibilityValue("\(position) of \(count)")
                .accessibilityIdentifier("discovery-card-\(card.id)")
            }

            HStack(spacing: 10) {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Previous personalized card")
                .accessibilityIdentifier("host-presentation-previous")

                Text("\(position) / \(count)")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 38)

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.glassProminent)
                .tint(accent)
                .accessibilityLabel("Next personalized card")
                .accessibilityIdentifier("host-presentation-next")
            }
        }
        .frame(width: 276)
        .id(card.id)
        .transition(
            reduceMotion
                ? .opacity
                : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
        )
        .animation(
            reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.82),
            value: card.id
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 28)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else {
                        return
                    }
                    if value.translation.width < 0 {
                        onNext()
                    } else {
                        onPrevious()
                    }
                }
        )
    }

    private var accessibilityLabel: String {
        if let score = card.finalScore {
            return """
            Final. \(score.visitorTeam) \(score.visitorRuns), \
            \(score.homeTeam) \(score.homeRuns). \
            Winning pitcher \(score.winningPitcher), \(score.winningPitcherLine). \
            Losing pitcher \(score.losingPitcher), \(score.losingPitcherLine).
            """
        }

        if let standings = card.standings {
            return """
            \(standings.teamName) are \
            \(standingsOrdinal(standings.divisionPosition)) of \
            \(standings.divisionTeamCount) in the \(standings.division) at \
            \(standings.record), \(standings.gamesBack) games back. \
            They are \(standings.lastTen) in their last ten with a \
            \(standings.streak) streak. Their run differential is \
            \(standings.runDifferential); only the \
            \(standings.comparisonTeam) are worse at \
            \(standings.comparisonRunDifferential). Next: \
            \(standings.nextOpponent), \(standings.nextGameDate), \
            \(standings.nextGameTime) at \(standings.nextGameVenue).
            """
        }

        if let story = card.playerStory {
            return """
            \(story.kicker). \(story.playerName), \(story.teamName). \
            \(story.headline) \(story.summary)
            """
        }

        if let dailyDrop = card.dailyDrop {
            return """
            \(dailyDrop.eyebrow). \(dailyDrop.title). \
            Story, three-question quiz, pack rip, and \
            \(dailyDrop.rewardSticker.playerName) sticker reward.
            """
        }

        return "\(card.title). \(card.whyItMatters)"
    }

    private var accessibilityHint: String {
        if card.dailyDrop != nil {
            return "Start the daily baseball story and quiz"
        }
        if card.playerStory != nil {
            return "Open the player story full screen"
        }
        return "Search \(card.destinationQuery)"
    }
}

struct SearchResultPresentationDeck: View {
    private let cardScale: CGFloat = 1.14

    let experience: BaseballSearchExperience
    let reduceMotion: Bool
    let onOpenPlayerGallery: (BaseballPlayerCard) -> Void
    @State private var activeIndex = 0

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if let activeModule {
                let content = activeModule.featuredContent

                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(content.accent.opacity(0.08))
                        .frame(width: 249, height: 234)
                        .offset(x: -14, y: 14)
                        .rotationEffect(.degrees(-2))

                    if case .player(let player) = activeModule,
                       !player.gallery.isEmpty {
                        Button {
                            onOpenPlayerGallery(player)
                        } label: {
                            FeaturedResultCard(
                                module: activeModule,
                                compact: true
                            )
                            .frame(
                                width: 230,
                                height: 215,
                                alignment: .topLeading
                            )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(cardScale)
                        .frame(width: 264, height: 247)
                        .accessibilityLabel(
                            "Open \(player.name), \(player.teamName), image gallery and quiz"
                        )
                        .accessibilityHint(
                            "Shows more archival photos and a quiz for a collectible card"
                        )
                        .accessibilityIdentifier(
                            "search-result-card-open-gallery"
                        )
                    } else {
                        FeaturedResultCard(
                            module: activeModule,
                            compact: true
                        )
                        .frame(
                            width: 230,
                            height: 215,
                            alignment: .topLeading
                        )
                        .scaleEffect(cardScale)
                        .frame(width: 264, height: 247)
                    }
                }
                .accessibilityIdentifier("search-result-card")

                HStack(spacing: 10) {
                    Button {
                        move(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Previous search result")
                    .accessibilityIdentifier("search-results-previous")

                    Text("\(boundedIndex + 1) / \(resultModules.count)")
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 38)

                    Button {
                        move(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(content.accent)
                    .accessibilityLabel("Next search result")
                    .accessibilityIdentifier("search-results-next")
                }
            }
        }
        .frame(width: 276)
        .animation(
            reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.82),
            value: activeIndex
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 28)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else {
                        return
                    }
                    move(by: value.translation.width < 0 ? 1 : -1)
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-results-deck")
    }

    private var resultModules: [BaseballResultModule] {
        experience.modules.filter(\.isPreviewModule)
    }

    private var boundedIndex: Int {
        guard !resultModules.isEmpty else { return 0 }
        return min(activeIndex, resultModules.count - 1)
    }

    private var activeModule: BaseballResultModule? {
        guard !resultModules.isEmpty else { return nil }
        return resultModules[boundedIndex]
    }

    private func move(by offset: Int) {
        guard !resultModules.isEmpty else { return }
        let proposed = (boundedIndex + offset) % resultModules.count
        activeIndex = proposed >= 0 ? proposed : proposed + resultModules.count
    }
}

private struct FinalScoreDiscoveryCardContent: View {
    let score: BaseballFinalScoreSnapshot

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("FINAL")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color(white: 0.34))

                Spacer()

                scoreHeaders
            }
            .padding(.bottom, 7)

            Divider()

            VStack(spacing: 7) {
                FinalScoreTeamRow(
                    abbreviation: score.visitorAbbreviation,
                    team: score.visitorTeam,
                    record: score.visitorRecord,
                    runs: score.visitorRuns,
                    hits: score.visitorHits,
                    errors: score.visitorErrors,
                    isHomeTeam: false
                )

                FinalScoreTeamRow(
                    abbreviation: score.homeAbbreviation,
                    team: score.homeTeam,
                    record: score.homeRecord,
                    runs: score.homeRuns,
                    hits: score.homeHits,
                    errors: score.homeErrors,
                    isHomeTeam: true
                )
            }
            .padding(.vertical, 9)

            Divider()

            HStack(alignment: .top, spacing: 10) {
                PitcherDecision(
                    decision: "W",
                    name: score.winningPitcher,
                    line: score.winningPitcherLine,
                    color: Color(red: 0.94, green: 0.70, blue: 0.12)
                )
                PitcherDecision(
                    decision: "L",
                    name: score.losingPitcher,
                    line: score.losingPitcherLine,
                    color: Color(white: 0.32)
                )
            }
            .padding(.vertical, 9)

            Divider()

            HStack {
                ForEach(["Watch", "Wrap", "Box", "Story"], id: \.self) { action in
                    Text(action)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(red: 0.02, green: 0.28, blue: 0.78))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
        }
        .padding(13)
        .frame(width: 230, height: 215)
        .background(
            Color.white,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
    }

    private var scoreHeaders: some View {
        HStack(spacing: 4) {
            ForEach(["R", "H", "E"], id: \.self) { header in
                Text(header)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(white: 0.28))
                    .frame(width: 20)
            }
        }
    }
}

private struct PlayerStoryDiscoveryCardContent: View {
    let story: BaseballPlayerStorySnapshot

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PlayerStoryRemoteImage(url: story.imageURL)
                .frame(width: 230, height: 215)
                .clipped()

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.24),
                    .black.opacity(0.92),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(story.playerName.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.82))

                Text(story.headline)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text("BEST OF LAST 10  •  \(story.sourceName.uppercased())")
                    .font(.system(size: 7, weight: .bold))
                    .tracking(0.45)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }
            .padding(15)

            HStack {
                Text(story.kicker)
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.7)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.58), in: Capsule())

                Spacer()

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(.black.opacity(0.58), in: Circle())
            }
            .padding(13)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 230, height: 215)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 12, y: 5)
    }
}

private struct PlayerStoryRemoteImage: View {
    let url: URL

    var body: some View {
        GeometryReader { proxy in
            AsyncImage(url: url, transaction: Transaction(animation: .easeOut)) { phase in
                switch phase {
                case .success(let image):
                    ZStack {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.height
                            )
                            .scaleEffect(1.08)
                            .blur(radius: 18)
                            .opacity(0.58)

                        image
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.height
                            )
                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .background(Color.black.opacity(0.30))
                case .failure:
                    playerStoryPlaceholder
                case .empty:
                    playerStoryPlaceholder
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                @unknown default:
                    playerStoryPlaceholder
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var playerStoryPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.23, green: 0.10, blue: 0.31),
                    Color(red: 0.06, green: 0.19, blue: 0.32),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "figure.baseball")
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.white.opacity(0.38))
        }
    }
}

private struct DynamicStandingsDiscoveryCardContent: View {
    let standings: BaseballStandingsSnapshot
    let reduceMotion: Bool

    @State private var spotlight = 0

    var body: some View {
        VStack(spacing: 0) {
            standingsHeader

            Divider()
                .padding(.vertical, 8)

            ZStack {
                spotlightContent
                    .id(spotlight)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                    )
            }
            .frame(maxWidth: .infinity, minHeight: 88, maxHeight: 88)
            .clipped()

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == spotlight
                                ? Color(red: 0.40, green: 0.16, blue: 0.54)
                                : Color.black.opacity(0.13)
                        )
                        .frame(width: index == spotlight ? 16 : 5, height: 5)
                }
            }
            .padding(.top, 8)
        }
        .padding(13)
        .frame(width: 230, height: 215)
        .background(
            Color.white,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(3.4))
                } catch {
                    return
                }

                withAnimation(
                    reduceMotion
                        ? nil
                        : .spring(response: 0.42, dampingFraction: 0.86)
                ) {
                    spotlight = (spotlight + 1) % 3
                }
            }
        }
    }

    private var standingsHeader: some View {
        HStack(spacing: 8) {
            Text(standings.teamAbbreviation)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 29, height: 29)
                .background(Color(red: 0.23, green: 0.20, blue: 0.30), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(standings.division.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.7)
                    .foregroundStyle(Color(white: 0.38))
                Text(standings.teamName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(white: 0.12))
                    .lineLimit(1)
                Text("\(standings.record)  •  \(standings.gamesBack) GB")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color(white: 0.43))
            }

            Spacer(minLength: 2)

            VStack(alignment: .trailing, spacing: 0) {
                Text(standingsOrdinal(standings.divisionPosition).uppercased())
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color(red: 0.40, green: 0.16, blue: 0.54))
                Text("OF \(standings.divisionTeamCount)")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color(white: 0.43))
            }
        }
    }

    @ViewBuilder
    private var spotlightContent: some View {
        switch spotlight {
        case 0:
            recentFormSpotlight
        case 1:
            runDifferentialSpotlight
        default:
            nextGameSpotlight
        }
    }

    private var recentFormSpotlight: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("RECENT FORM")
                .font(.system(size: 8, weight: .black))
                .tracking(0.7)
                .foregroundStyle(Color(white: 0.42))

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(standings.lastTen)
                        .font(.system(size: 29, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.76, green: 0.12, blue: 0.16))
                    Text("LAST 10")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color(white: 0.43))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text(standings.streak)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Color(red: 0.76, green: 0.12, blue: 0.16),
                            in: Capsule()
                        )
                    Text("2-GAME SKID")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color(red: 0.76, green: 0.12, blue: 0.16))
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            Color(red: 0.76, green: 0.12, blue: 0.16).opacity(0.07),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var runDifferentialSpotlight: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RUN DIFFERENTIAL")
                .font(.system(size: 8, weight: .black))
                .tracking(0.7)
                .foregroundStyle(Color(white: 0.42))

            HStack(spacing: 10) {
                RunDifferentialMetric(
                    abbreviation: standings.teamAbbreviation,
                    value: standings.runDifferential,
                    emphasized: true
                )

                Divider()
                    .frame(height: 36)

                RunDifferentialMetric(
                    abbreviation: standings.comparisonTeamAbbreviation,
                    value: standings.comparisonRunDifferential,
                    emphasized: false
                )
            }

            Text("Only the \(standings.comparisonTeam) are worse in MLB.")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color(white: 0.32))
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            Color(red: 0.95, green: 0.56, blue: 0.12).opacity(0.09),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var nextGameSpotlight: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("NEXT GAME  •  \(standings.nextGameDate.uppercased())")
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.5)
                    .foregroundStyle(Color(white: 0.42))

                Spacer()

                Text(standings.nextGameTime)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color(white: 0.32))
            }

            HStack(spacing: 7) {
                TeamMatchupMark(
                    abbreviation: standings.teamAbbreviation,
                    record: standings.record,
                    color: Color(red: 0.23, green: 0.20, blue: 0.30)
                )

                Text("@")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(white: 0.45))

                TeamMatchupMark(
                    abbreviation: standings.nextOpponentAbbreviation,
                    record: standings.nextOpponentRecord,
                    color: Color(red: 0.24, green: 0.11, blue: 0.04)
                )

                Spacer()

                Text("\(standingsOrdinal(standings.nextOpponentDivisionPosition)) \(standings.division)")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color(white: 0.38))
            }

            Text("\(standings.nextGameVenue)  •  \(standings.probablePitchers)")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color(white: 0.32))
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            Color(red: 0.02, green: 0.28, blue: 0.78).opacity(0.07),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}

private struct RunDifferentialMetric: View {
    let abbreviation: String
    let value: Int
    let emphasized: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(abbreviation)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Color(white: 0.40))
            Text("\(value)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(
                    emphasized
                        ? Color(red: 0.76, green: 0.12, blue: 0.16)
                        : Color(white: 0.28)
                )
                .monospacedDigit()
        }
    }
}

private struct TeamMatchupMark: View {
    let abbreviation: String
    let record: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(abbreviation)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(color, in: Circle())

            Text(record)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color(white: 0.30))
        }
    }
}

private func standingsOrdinal(_ value: Int) -> String {
    let remainder100 = value % 100
    let suffix: String

    if 11...13 ~= remainder100 {
        suffix = "th"
    } else {
        switch value % 10 {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
    }

    return "\(value)\(suffix)"
}

private struct FinalScoreTeamRow: View {
    let abbreviation: String
    let team: String
    let record: String
    let runs: Int
    let hits: Int
    let errors: Int
    let isHomeTeam: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(abbreviation)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(isHomeTeam ? .yellow : .white)
                .frame(width: 22, height: 22)
                .background(
                    isHomeTeam
                        ? Color(red: 0.02, green: 0.12, blue: 0.27)
                        : Color(red: 0.22, green: 0.20, blue: 0.27),
                    in: Circle()
                )

            HStack(spacing: 4) {
                Text(team)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(white: 0.13))
                Text(record)
                    .font(.caption2)
                    .foregroundStyle(Color(white: 0.42))
            }
            .frame(width: 94, alignment: .leading)
            .lineLimit(1)

            Spacer(minLength: 0)

            scoreValue(runs)
            scoreValue(hits)
            scoreValue(errors)
        }
    }

    private func scoreValue(_ value: Int) -> some View {
        Text("\(value)")
            .font(.caption.weight(.bold).monospacedDigit())
            .foregroundStyle(Color(white: 0.13))
            .frame(width: 20)
            .lineLimit(1)
    }
}

private struct PitcherDecision: View {
    let decision: String
    let name: String
    let line: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(decision)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(color, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("\(decision): \(name)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(white: 0.32))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(line)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(Color(white: 0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SearchLoadingCard: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(.purple)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .glassEffect(
            .regular.tint(.purple.opacity(0.1)),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("baseball-search-loading")
    }
}

private struct FeaturedResultCard: View {
    let module: BaseballResultModule
    var compact = false

    @ViewBuilder
    var body: some View {
        if case .player(let player) = module,
           let leadImage = player.gallery.first {
            PlayerGalleryResultCard(
                player: player,
                leadImage: leadImage
            )
        } else {
            genericCard
        }
    }

    private var genericCard: some View {
        let content = module.featuredContent

        return VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Label(content.eyebrow, systemImage: content.systemImage)
                    .font(.caption2.weight(.black))
                    .tracking(1)
                    .foregroundStyle(content.accent)
            }

            Text(content.title)
                .font(compact ? .title3.bold() : .title2.bold())
                .lineLimit(compact ? 3 : nil)
            Text(content.metadata)
                .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if !content.summary.isEmpty {
                Text(content.summary)
                    .font(compact ? .caption : .body)
                    .foregroundStyle(compact ? .secondary : .primary)
                    .lineLimit(compact ? 4 : nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(compact ? 15 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            .regular.tint(content.accent.opacity(0.12)),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("baseball-featured-result")
    }
}

private struct PlayerGalleryResultCard: View {
    let player: BaseballPlayerCard
    let leadImage: BaseballPlayerGalleryImage

    private let philliesRed = Color(
        red: 0.91,
        green: 0.08,
        blue: 0.18
    )

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            SearchResultPlayerImage(urlString: leadImage.imageURL)

            LinearGradient(
                colors: [
                    .black.opacity(0.02),
                    .black.opacity(0.24),
                    .black.opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("HALL OF FAME • NO. 20")
                    .font(.system(size: 8, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.76))

                Text(player.name)
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(.white)

                Text("\(player.teamName.uppercased()) • \(player.position)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.74))

                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                    Text("QUIZ + LEGENDARY CARD")
                }
                .font(.system(size: 8, weight: .black))
                .tracking(0.55)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(philliesRed, in: Capsule())
            }
            .padding(15)

            HStack {
                Text("TAP TO EXPLORE")
                    .font(.system(size: 7, weight: .black))
                    .tracking(0.7)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.58), in: Capsule())

                Spacer()

                Image(systemName: "photo.stack.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(philliesRed, in: Circle())
            }
            .padding(13)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 230, height: 215)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(philliesRed.opacity(0.62), lineWidth: 1.5)
        }
        .shadow(color: philliesRed.opacity(0.22), radius: 16, y: 7)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("baseball-featured-result")
    }
}

private struct SearchResultPlayerImage: View {
    let urlString: String

    var body: some View {
        GeometryReader { proxy in
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    placeholder
                        .overlay {
                            ProgressView().tint(.white)
                        }
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.64, green: 0.02, blue: 0.08),
                    .black,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "figure.baseball")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(.white.opacity(0.34))
        }
    }
}

struct SearchFailureCard: View {
    let failure: BaseballSearchFailurePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "baseball.diamond.bases")
                .font(.title2)
                .foregroundStyle(.orange)
            Text(failure.title)
                .font(.title3.bold())
            Text(failure.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .padding(17)
        .frame(
            maxWidth: .infinity,
            minHeight: 170,
            alignment: .leading
        )
        .glassEffect(
            .regular.tint(.orange.opacity(0.1)),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .accessibilityIdentifier("baseball-search-error")
    }
}

private struct ModulePreview {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    let destinationQuery: String?
}

private struct FeaturedResultContent {
    let eyebrow: String
    let title: String
    let metadata: String
    let summary: String
    let systemImage: String
    let accent: Color
}

private extension BaseballResultModule {
    var isPreviewModule: Bool {
        switch self {
        case .hostReaction, .whyThisMatters:
            false
        default:
            true
        }
    }

    var featuredContent: FeaturedResultContent {
        switch self {
        case .player(let value):
            .init(
                eyebrow: "PLAYER PROFILE",
                title: value.name,
                metadata: "\(value.teamName) • \(value.position)",
                summary: value.summary,
                systemImage: "figure.baseball",
                accent: .cyan
            )
        case .team(let value):
            .init(
                eyebrow: "TEAM PROFILE",
                title: value.name,
                metadata: value.abbreviation,
                summary: value.summary,
                systemImage: "shield.lefthalf.filled",
                accent: .purple
            )
        default:
            .init(
                eyebrow: "RESULT",
                title: preview.title,
                metadata: preview.subtitle,
                summary: "",
                systemImage: preview.systemImage,
                accent: preview.accent
            )
        }
    }

    var preview: ModulePreview {
        switch self {
        case .player(let value):
            .init(
                eyebrow: "PLAYER",
                title: value.name,
                subtitle: "\(value.teamName) • \(value.position)",
                systemImage: "figure.baseball",
                accent: .cyan,
                destinationQuery: value.name
            )
        case .team(let value):
            .init(
                eyebrow: "TEAM",
                title: value.name,
                subtitle: value.summary,
                systemImage: "shield.lefthalf.filled",
                accent: .purple,
                destinationQuery: value.name
            )
        case .game(let value):
            .init(
                eyebrow: value.status == .live ? "LIVE" : "GAME",
                title: "\(value.awayTeam) at \(value.homeTeam)",
                subtitle: "\(value.venue) • \(value.statusText)",
                systemImage: "baseball.diamond.bases",
                accent: .orange,
                destinationQuery: "\(value.homeTeam) game"
            )
        case .standings(let value):
            .init(
                eyebrow: "STANDINGS",
                title: value.title,
                subtitle: value.summary,
                systemImage: "chart.line.uptrend.xyaxis",
                accent: .mint,
                destinationQuery: "How does tonight affect the Wild Card?"
            )
        case .highlight(let value):
            .init(
                eyebrow: "HIGHLIGHT",
                title: value.title,
                subtitle: "\(value.durationSeconds) sec • \(value.subtitle)",
                systemImage: "play.rectangle.fill",
                accent: .pink,
                destinationQuery: nil
            )
        case .statcast(let value):
            .init(
                eyebrow: "STATCAST",
                title: value.title,
                subtitle: "\(value.metricName): \(value.metricValue)",
                systemImage: "waveform.path.ecg",
                accent: .cyan,
                destinationQuery: nil
            )
        case .comparison(let value):
            .init(
                eyebrow: "COMPARE",
                title: "\(value.leftName) vs. \(value.rightName)",
                subtitle: value.headline,
                systemImage: "arrow.left.arrow.right",
                accent: .purple,
                destinationQuery: "Compare \(value.leftName) and \(value.rightName)"
            )
        case .personalMemory(let value):
            .init(
                eyebrow: "YOUR BASEBALL",
                title: value.title,
                subtitle: value.detail,
                systemImage: "ticket.fill",
                accent: .orange,
                destinationQuery: nil
            )
        case .relatedSearches(let value):
            .init(
                eyebrow: "KEEP EXPLORING",
                title: value.searches.first ?? "Related searches",
                subtitle: value.searches.dropFirst().joined(separator: " • "),
                systemImage: "point.3.connected.trianglepath.dotted",
                accent: .mint,
                destinationQuery: value.searches.first
            )
        case .watchNext(let value):
            .init(
                eyebrow: "WATCH NEXT",
                title: value.title,
                subtitle: value.reason,
                systemImage: "play.fill",
                accent: .pink,
                destinationQuery: value.query
            )
        case .hostReaction(let value):
            .init(
                eyebrow: "HOST OPINION",
                title: value.line,
                subtitle: value.providerName,
                systemImage: "sparkles",
                accent: .purple,
                destinationQuery: nil
            )
        case .whyThisMatters(let value):
            .init(
                eyebrow: "WHY THIS MATTERS",
                title: value.title,
                subtitle: value.explanation,
                systemImage: "heart.text.clipboard.fill",
                accent: .cyan,
                destinationQuery: nil
            )
        }
    }
}
