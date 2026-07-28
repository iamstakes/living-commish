import SwiftUI

struct BaseballSearchHomeView: View {
    @Environment(BaseballSearchEnvironment.self) private var environment
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var environment = environment

        ZStack {
            BaseballHomeBackground()

            ScrollView {
                VStack(spacing: 24) {
                    searchSection
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
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(isShowingResults ? "Search again" : "Search")
                        .font(
                            .system(
                                isShowingResults ? .title : .largeTitle,
                                design: .rounded,
                                weight: .bold
                            )
                        )
                        .fontWidth(.expanded)
                        .accessibilityIdentifier("baseball-search-title")

                    Spacer(minLength: 12)
                    profileBadge
                }

                if !isShowingResults {
                    Text("Players, teams, games, history, and the moments that matter to you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextField(
                            "Try “How does tonight affect the Wild Card?”",
                            text: Bindable(environment).searchText
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
                            Button {
                                environment.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear search")
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
                    .tint(.purple)
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
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-search-section")
    }

    private var profileBadge: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(.purple.gradient)
                .frame(width: 24, height: 24)
                .overlay {
                    Text(String(environment.profile.name.prefix(1)))
                        .font(.caption2.bold())
                }
            VStack(alignment: .leading, spacing: 0) {
                Text(environment.profile.name)
                    .font(.caption.bold())
                Text("Rockies")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .glassEffect(.clear, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(environment.profile.name), \(environment.profile.favoriteTeam) fan"
        )
    }

    @ViewBuilder
    private var stateContent: some View {
        switch environment.state {
        case .discovering:
            discoverySection
        case .interpreting(let query):
            HostPresentationStage(
                host: environment.host,
                height: 350,
                accent: .purple
            ) {
                SearchLoadingCard(
                    title: "Reading your question",
                    detail: query
                )
                .frame(width: 238)
                .padding(.top, 42)
            }
        case .loading(let plan):
            HostPresentationStage(
                host: environment.host,
                height: 350,
                accent: .cyan
            ) {
                SearchLoadingCard(
                    title: "Building your result",
                    detail: "\(plan.requestedModules.count) modules for \(environment.profile.name)"
                )
                .frame(width: 238)
                .padding(.top, 42)
            }
        case .presenting(let experience):
            SearchExperienceOverview(
                experience: experience,
                host: environment.host,
                onReset: {
                    environment.resetToDiscovery()
                    Task { await environment.loadDiscovery() }
                },
                onSearch: runSearch
            )
        case .failed(let failure):
            SearchFailureCard(
                failure: failure,
                onSuggestion: runSearch
            )
        }
    }

    private var discoverySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("For You")
                    .font(.title2.bold())
                Text("Personalized for you")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let activeDiscoveryCard {
                HostPresentationStage(
                    host: environment.host,
                    height: 440,
                    accent: discoveryAccent(for: activeDiscoveryCardIndex),
                    hostScale: 1.28
                ) {
                    DiscoveryPresentationDeck(
                        card: activeDiscoveryCard,
                        accent: discoveryAccent(for: activeDiscoveryCardIndex),
                        position: activeDiscoveryCardIndex + 1,
                        count: environment.discoveryCards.count,
                        reduceMotion: reduceMotion,
                        onPrevious: {
                            environment.moveDiscoveryCard(by: -1)
                        },
                        onNext: {
                            environment.moveDiscoveryCard(by: 1)
                        },
                        onOpen: {
                            runSearch(activeDiscoveryCard.destinationQuery)
                        }
                    )
                    .padding(.top, 20)
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

            quickSearches
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-discovery-section")
    }

    private var quickSearches: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("QUICK SEARCHES")
                .font(.caption2.weight(.black))
                .tracking(1.1)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([
                        "Aaron Judge",
                        "Games tonight",
                        "Compare Judge and Ohtani",
                        "My last Rockies game",
                    ], id: \.self) { query in
                        Button(query) {
                            runSearch(query)
                        }
                        .buttonStyle(.glass)
                        .font(.caption.weight(.semibold))
                        .accessibilityIdentifier(
                            "quick-search-\(query.lowercased().replacingOccurrences(of: " ", with: "-"))"
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var isShowingResults: Bool {
        if case .presenting = environment.state { return true }
        return false
    }

    private var activeDiscoveryCard: BaseballDiscoveryCard? {
        environment.discoveryCards.first {
            $0.id == environment.activeDiscoveryCardID
        } ?? environment.discoveryCards.first
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
        [.purple, .cyan, .orange, .pink, .mint][index % 5]
    }

    private func submitSearch() {
        let query = environment.searchText
        runSearch(query)
    }

    private func runSearch(_ query: String) {
        isSearchFocused = false
        Task { await environment.search(query) }
    }
}

private struct HostPresentationStage<Content: View>: View {
    let host: any AnimatedHostControlling
    let height: CGFloat
    let accent: Color
    let hostScale: CGFloat
    private let content: Content

    init(
        host: any AnimatedHostControlling,
        height: CGFloat,
        accent: Color,
        hostScale: CGFloat = 1.2,
        @ViewBuilder content: () -> Content
    ) {
        self.host = host
        self.height = height
        self.accent = accent
        self.hostScale = hostScale
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
                                Color.purple.opacity(0.07),
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
                    height: height - 10,
                    accent: accent,
                    contentScale: hostScale,
                    contentOffset: CGSize(width: -8, height: 2)
                )
                .frame(width: proxy.size.width * 0.86)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottomTrailing
                )
                .offset(x: proxy.size.width * 0.21, y: 8)
                .zIndex(1)

                content
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .zIndex(2)

                HostReadyBadge(host: host)
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topTrailing
                    )
                    .zIndex(3)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("host-presentation-stage")
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
    let card: BaseballDiscoveryCard
    let accent: Color
    let position: Int
    let count: Int
    let reduceMotion: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(accent.opacity(0.08))
                    .frame(width: 218, height: 205)
                    .offset(x: -12, y: 12)
                    .rotationEffect(.degrees(-2))

                Button(action: onOpen) {
                    Group {
                        if let finalScore = card.finalScore {
                            FinalScoreDiscoveryCardContent(score: finalScore)
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
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint("Search \(card.destinationQuery)")
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
        .frame(width: 240)
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
        guard let score = card.finalScore else {
            return "\(card.title). \(card.whyItMatters)"
        }

        return """
        Final. \(score.visitorTeam) \(score.visitorRuns), \
        \(score.homeTeam) \(score.homeRuns). \
        Winning pitcher \(score.winningPitcher), \(score.winningPitcherLine). \
        Losing pitcher \(score.losingPitcher), \(score.losingPitcherLine).
        """
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

private struct SearchLoadingCard: View {
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

private struct SearchExperienceOverview: View {
    let experience: BaseballSearchExperience
    let host: any AnimatedHostControlling
    let onReset: () -> Void
    let onSearch: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SEARCH EXPERIENCE")
                        .font(.caption2.weight(.black))
                        .tracking(1.1)
                        .foregroundStyle(.purple)
                    Text(experience.displayTitle)
                        .font(.title2.bold())
                        .accessibilityIdentifier("baseball-results-title")
                }
                Spacer()
                Button(action: onReset) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Back to discovery")
                .accessibilityIdentifier("baseball-results-close")
            }

            if let presentationModule {
                ResultPresentationStage(
                    host: host,
                    module: presentationModule,
                    reaction: reaction
                )
            }

            if !remainingPreviewModules.isEmpty {
                Text("Go deeper")
                    .font(.headline)

                LazyVStack(spacing: 11) {
                    ForEach(remainingPreviewModules.prefix(5)) { module in
                        ModulePreviewCard(module: module, onSearch: onSearch)
                    }
                }
            }

            if let why = experience.modules.compactMap(\.whyThisMatters).first {
                VStack(alignment: .leading, spacing: 7) {
                    Text(why.title)
                        .font(.headline)
                    Text(why.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(
                    .clear.tint(.cyan.opacity(0.1)),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("baseball-results-overview")
    }

    private var presentationModule: BaseballResultModule? {
        experience.modules.first(where: \.isPreviewModule)
    }

    private var reaction: BaseballHostReaction? {
        experience.modules.compactMap(\.hostReaction).first
    }

    private var remainingPreviewModules: [BaseballResultModule] {
        experience.modules.filter { module in
            module.isPreviewModule && module.id != presentationModule?.id
        }
    }
}

private struct FeaturedResultCard: View {
    let module: BaseballResultModule
    var compact = false

    var body: some View {
        let content = module.featuredContent

        VStack(alignment: .leading, spacing: 11) {
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

private struct ResultPresentationStage: View {
    let host: any AnimatedHostControlling
    let module: BaseballResultModule
    let reaction: BaseballHostReaction?

    var body: some View {
        let content = module.featuredContent

        HostPresentationStage(
            host: host,
            height: 430,
            accent: content.accent,
            hostScale: 1.28
        ) {
            ZStack(alignment: .topLeading) {
                FeaturedResultCard(module: module, compact: true)
                    .frame(width: 230)
                    .padding(.top, 18)

                if let reaction {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(
                            reaction.kind.displayName.uppercased(),
                            systemImage: "sparkles"
                        )
                        .font(.caption2.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(.purple)
                        Text(reaction.line)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(width: 286, alignment: .leading)
                    .glassEffect(
                        .regular.tint(.purple.opacity(0.18)),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottomLeading
                    )
                    .padding(.bottom, 10)
                }
            }
        }
        .accessibilityIdentifier("result-presentation-stage")
    }
}

private struct ModulePreviewCard: View {
    let module: BaseballResultModule
    let onSearch: (String) -> Void

    var body: some View {
        let preview = module.preview

        HStack(spacing: 14) {
            Image(systemName: preview.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(preview.accent)
                .frame(width: 42, height: 42)
                .background(preview.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(preview.eyebrow)
                        .font(.caption2.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(preview.accent)
                }
                Text(preview.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(preview.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if let query = preview.destinationQuery {
                Button {
                    onSearch(query)
                } label: {
                    Image(systemName: "arrow.up.right")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Search \(query)")
            }
        }
        .padding(15)
        .glassEffect(
            .clear.tint(preview.accent.opacity(0.07)),
            in: RoundedRectangle(cornerRadius: 21, style: .continuous)
        )
    }
}

private struct SearchFailureCard: View {
    let failure: BaseballSearchFailurePresentation
    let onSuggestion: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "baseball.diamond.bases")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(failure.title)
                .font(.title2.bold())
            Text(failure.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("TRY ONE OF THESE")
                .font(.caption2.weight(.black))
                .tracking(1)
                .foregroundStyle(.secondary)
            ForEach(failure.recoverySuggestions, id: \.self) { suggestion in
                Button(suggestion) {
                    onSuggestion(suggestion)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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

private extension BaseballSearchExperience {
    var displayTitle: String {
        switch query.intent {
        case .favoriteTeam, .favoritePlayer, .entityLookup, .teamLookup:
            query.entities.first?.canonicalName ?? query.rawText
        default:
            query.rawText
        }
    }
}

private extension BaseballResultModule {
    var hostReaction: BaseballHostReaction? {
        if case .hostReaction(let value) = self { return value }
        return nil
    }

    var whyThisMatters: BaseballWhyThisMattersCard? {
        if case .whyThisMatters(let value) = self { return value }
        return nil
    }

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

private struct BaseballHomeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.025, green: 0.055, blue: 0.09),
                    Color(red: 0.07, green: 0.035, blue: 0.12),
                    Color(red: 0.02, green: 0.025, blue: 0.055),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.purple.opacity(0.17))
                .frame(width: 340, height: 340)
                .blur(radius: 70)
                .offset(x: 170, y: -280)

            Circle()
                .fill(.cyan.opacity(0.1))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -170, y: 320)

            Canvas { context, size in
                let spacing: CGFloat = 34
                var path = Path()
                for x in stride(from: 0, through: size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, through: size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.white.opacity(0.018)), lineWidth: 0.5)
            }
        }
        .ignoresSafeArea()
    }
}
