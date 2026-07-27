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
                    header
                    searchSection
                    hero
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

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "baseball.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .glassEffect(
                    .regular.tint(.purple.opacity(0.35)),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("BASEBALL LIVING HOST")
                    .font(.caption.weight(.black))
                    .fontWidth(.expanded)
                    .tracking(1.7)
                    .foregroundStyle(.white.opacity(0.94))
                    .accessibilityIdentifier("baseball-home-title")
                Text("The game, shaped around you")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

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
    }

    private var hero: some View {
        VStack(spacing: 2) {
            AnimatedHostView(
                host: environment.host,
                height: isShowingResults ? 210 : 230,
                accent: .purple
            )

            HStack(spacing: 7) {
                Circle()
                    .fill(environment.host.isReady ? .green : .orange)
                    .frame(width: 7, height: 7)
                Text(environment.host.isReady ? "Your host is ready" : "Host is warming up")
                    .font(.caption.weight(.semibold))
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(environment.host.descriptor.disclosure)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 6) {
                Text(isShowingResults ? "Search again" : "Search baseball")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .fontWidth(.expanded)
                Text("Players, teams, games, history, and the moments that matter to you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                        .accessibilityLabel("Search baseball")
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

    @ViewBuilder
    private var stateContent: some View {
        switch environment.state {
        case .discovering:
            discoverySection
        case .interpreting(let query):
            SearchLoadingCard(
                title: "Reading the baseball in your question",
                detail: query
            )
        case .loading(let plan):
            SearchLoadingCard(
                title: "Building your baseball experience",
                detail: "\(plan.requestedModules.count) visual modules, ordered for \(environment.profile.name)"
            )
        case .presenting(let experience):
            SearchExperienceOverview(
                experience: experience,
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
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Already worth knowing")
                        .font(.title2.bold())
                    Text("Picked from your teams, habits, and baseball history.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("PROTOTYPE DATA")
                    .font(.caption2.weight(.black))
                    .tracking(0.8)
                    .foregroundStyle(.orange)
            }

            if environment.discoveryCards.isEmpty {
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
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    GlassEffectContainer(spacing: 12) {
                        HStack(spacing: 12) {
                            ForEach(Array(environment.discoveryCards.enumerated()), id: \.element.id) { index, card in
                                DiscoveryCardButton(
                                    card: card,
                                    accent: discoveryAccent(for: index)
                                ) {
                                    runSearch(card.destinationQuery)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .contentMargins(.horizontal, 1, for: .scrollContent)
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

private struct DiscoveryCardButton: View {
    let card: BaseballDiscoveryCard
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
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
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(card.whyItMatters)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .padding(17)
            .frame(width: 250, height: 205, alignment: .leading)
            .glassEffect(
                .regular.tint(accent.opacity(0.12)).interactive(),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.title). \(card.whyItMatters)")
        .accessibilityHint("Search \(card.destinationQuery)")
        .accessibilityIdentifier("discovery-card-\(card.id)")
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
                    Text(experience.query.rawText)
                        .font(.title2.bold())
                }
                Spacer()
                Button(action: onReset) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Back to discovery")
                .accessibilityIdentifier("baseball-results-close")
            }

            if let reaction = experience.modules.compactMap(\.hostReaction).first {
                VStack(alignment: .leading, spacing: 8) {
                    Label(reaction.kind.displayName.uppercased(), systemImage: "sparkles")
                        .font(.caption2.weight(.black))
                        .tracking(1)
                        .foregroundStyle(.purple)
                    Text(reaction.line)
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(
                    .regular.tint(.purple.opacity(0.14)),
                    in: RoundedRectangle(cornerRadius: 25, style: .continuous)
                )
            }

            Text("Built for this search")
                .font(.headline)

            LazyVStack(spacing: 11) {
                ForEach(experience.modules.filter(\.isPreviewModule).prefix(5)) { module in
                    ModulePreviewCard(module: module, onSearch: onSearch)
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
                    if module.facts.contains(where: \.provenance.isMock) {
                        Text("PROTOTYPE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                    }
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
