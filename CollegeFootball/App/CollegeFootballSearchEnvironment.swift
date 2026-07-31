import Foundation
import Observation

@MainActor
struct CollegeFootballSearchDependencies {
    let profile: CollegeFootballFanProfileSnapshot
    let queryInterpreter: any CollegeFootballQueryInterpreting
    let planner: any CollegeFootballSearchPlanning
    let dataProvider: any CollegeFootballDataProviding
    let discoveryProvider: any CollegeFootballDiscoveryProviding
    let hostEditor: any CollegeFootballHostEditorializing
    let resultComposer: any CollegeFootballResultComposing
    let host: any AnimatedHostControlling
    let stickerStore: any CollegeFootballStickerStoring

    init(
        profile: CollegeFootballFanProfileSnapshot,
        queryInterpreter: any CollegeFootballQueryInterpreting,
        planner: any CollegeFootballSearchPlanning,
        dataProvider: any CollegeFootballDataProviding,
        discoveryProvider: any CollegeFootballDiscoveryProviding,
        hostEditor: any CollegeFootballHostEditorializing,
        resultComposer: any CollegeFootballResultComposing,
        host: any AnimatedHostControlling,
        stickerStore: any CollegeFootballStickerStoring = InMemoryCollegeFootballStickerStore()
    ) {
        self.profile = profile
        self.queryInterpreter = queryInterpreter
        self.planner = planner
        self.dataProvider = dataProvider
        self.discoveryProvider = discoveryProvider
        self.hostEditor = hostEditor
        self.resultComposer = resultComposer
        self.host = host
        self.stickerStore = stickerStore
    }

    static func prototype(bundle: Bundle = .main) -> CollegeFootballSearchDependencies {
        let arguments = ProcessInfo.processInfo.arguments
        let forceDeterministicSearch = arguments.contains("--collegeFootball-ui-testing")
            || arguments.contains("--collegeFootball-onboarding-ui-testing")
        let stickerStore: any CollegeFootballStickerStoring = forceDeterministicSearch
            ? InMemoryCollegeFootballStickerStore()
            : UserDefaultsCollegeFootballStickerStore()

        return CollegeFootballSearchDependencies(
            profile: MockMichaelProfile.value,
            queryInterpreter: AdaptiveCollegeFootballQueryInterpreter(
                forceDeterministicFallback: forceDeterministicSearch
            ),
            planner: DefaultCollegeFootballSearchPlanner(),
            dataProvider: MockCollegeFootballDataService(),
            discoveryProvider: MockCollegeFootballDiscoveryService(),
            hostEditor: DeterministicCollegeFootballHostEditor(),
            resultComposer: DefaultCollegeFootballResultComposer(),
            host: CommishHostAdapter(bundle: bundle),
            stickerStore: stickerStore
        )
    }
}

@MainActor
@Observable
final class CollegeFootballSearchEnvironment {
    private(set) var profile: CollegeFootballFanProfileSnapshot
    let host: any AnimatedHostControlling

    var searchText = ""
    private(set) var state: CollegeFootballSearchExperienceState = .discovering
    private(set) var discoveryCards: [CollegeFootballDiscoveryCard] = []
    private(set) var activeDiscoveryCardID: String?
    private(set) var discoveryError: String?
    private(set) var collectedStickerIDs: Set<String>
    private(set) var avatarStickerID: String?

    @ObservationIgnored private let queryInterpreter: any CollegeFootballQueryInterpreting
    @ObservationIgnored private let planner: any CollegeFootballSearchPlanning
    @ObservationIgnored private let dataProvider: any CollegeFootballDataProviding
    @ObservationIgnored private let discoveryProvider: any CollegeFootballDiscoveryProviding
    @ObservationIgnored private let hostEditor: any CollegeFootballHostEditorializing
    @ObservationIgnored private let resultComposer: any CollegeFootballResultComposing
    @ObservationIgnored private let stickerStore: any CollegeFootballStickerStoring

    init(dependencies: CollegeFootballSearchDependencies) {
        profile = dependencies.profile
        host = dependencies.host
        stickerStore = dependencies.stickerStore
        let storedStickerIDs = dependencies.stickerStore
            .loadCollectedStickerIDs()
        collectedStickerIDs = storedStickerIDs
        let storedAvatarStickerID = dependencies.stickerStore
            .loadAvatarStickerID()
        if let storedAvatarStickerID,
           storedStickerIDs.contains(storedAvatarStickerID) {
            avatarStickerID = storedAvatarStickerID
        } else {
            avatarStickerID = nil
        }
        queryInterpreter = dependencies.queryInterpreter
        planner = dependencies.planner
        dataProvider = dependencies.dataProvider
        discoveryProvider = dependencies.discoveryProvider
        hostEditor = dependencies.hostEditor
        resultComposer = dependencies.resultComposer
    }

    convenience init(bundle: Bundle = .main) {
        self.init(dependencies: .prototype(bundle: bundle))
    }

    var isSearching: Bool {
        switch state {
        case .interpreting, .loading: true
        case .discovering, .presenting, .failed: false
        }
    }

    var collectedStickers: [CollegeFootballSticker] {
        CollegeFootballStickerCatalog.all.filter {
            collectedStickerIDs.contains($0.id)
        }
    }

    var avatarSticker: CollegeFootballSticker? {
        CollegeFootballStickerCatalog.all.first {
            $0.id == avatarStickerID
        }
    }

    func hasCollected(_ sticker: CollegeFootballSticker) -> Bool {
        collectedStickerIDs.contains(sticker.id)
    }

    func collectSticker(_ sticker: CollegeFootballSticker) {
        guard !collectedStickerIDs.contains(sticker.id) else { return }
        collectedStickerIDs.insert(sticker.id)
        stickerStore.saveCollectedStickerIDs(collectedStickerIDs)
        host.perform(.celebrate)
    }

    func useStickerAsAvatar(_ sticker: CollegeFootballSticker) {
        guard collectedStickerIDs.contains(sticker.id) else { return }
        avatarStickerID = sticker.id
        stickerStore.saveAvatarStickerID(sticker.id)
        host.perform(.celebrate)
    }

    func resetStickerDemo() {
        collectedStickerIDs = []
        avatarStickerID = nil
        stickerStore.saveCollectedStickerIDs([])
        stickerStore.saveAvatarStickerID(nil)
        resetToDiscovery()
    }

    func updateProfile(_ updatedProfile: CollegeFootballFanProfileSnapshot) {
        guard profile != updatedProfile else { return }
        profile = updatedProfile
        searchText = ""
        state = .discovering
        discoveryCards = []
        activeDiscoveryCardID = nil
        discoveryError = nil
        host.reset()
    }

    func loadDiscovery() async {
        do {
            discoveryCards = try await discoveryProvider.cards(for: profile)
            discoveryError = nil
            if let activeDiscoveryCardID,
               discoveryCards.contains(where: { $0.id == activeDiscoveryCardID }) {
                presentDiscoveryCard(activeDiscoveryCardID)
            } else if let firstCard = discoveryCards.first {
                presentDiscoveryCard(firstCard.id)
            }
            if case .failed = state { state = .discovering }
        } catch {
            discoveryCards = []
            activeDiscoveryCardID = nil
            discoveryError = error.localizedDescription
        }
    }

    func presentDiscoveryCard(_ id: String) {
        guard let card = discoveryCards.first(where: { $0.id == id }) else { return }
        activeDiscoveryCardID = card.id
        host.perform(card.hostBehavior)
    }

    func moveDiscoveryCard(by offset: Int) {
        guard !discoveryCards.isEmpty else { return }
        let currentIndex = discoveryCards.firstIndex {
            $0.id == activeDiscoveryCardID
        } ?? 0
        let proposedIndex = (currentIndex + offset) % discoveryCards.count
        let nextIndex = proposedIndex >= 0
            ? proposedIndex
            : proposedIndex + discoveryCards.count
        presentDiscoveryCard(discoveryCards[nextIndex].id)
    }

    func submitSearch() async {
        await search(searchText)
    }

    func search(_ rawText: String) async {
        let cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            state = .failed(
                CollegeFootballSearchFailurePresentation(
                    title: "What should we search?",
                    message: CollegeFootballSearchArchitectureError.emptyQuery.localizedDescription,
                    recoverySuggestions: ["Travis Hunter", "Games this weekend", "Who should I watch?"]
                )
            )
            return
        }

        searchText = cleaned
        state = .interpreting(query: cleaned)
        host.perform(.think)

        do {
            let query = try await queryInterpreter.interpret(cleaned, profile: profile)
            guard query.intent != .unknown else {
                throw CollegeFootballSearchArchitectureError.needsRefinement(
                    query.ambiguity
                        ?? "Try a player, team, game, comparison, or playoff question."
                )
            }
            let plan = planner.plan(for: query)
            state = .loading(plan: plan)

            let snapshot = try await dataProvider.fetch(plan: plan, profile: profile)
            let editorial = try await hostEditor.editorial(
                for: plan,
                snapshot: snapshot,
                profile: profile
            )
            let experience = resultComposer.compose(
                plan: plan,
                snapshot: snapshot,
                editorial: editorial
            )
            host.perform(plan.hostBehavior)
            state = .presenting(experience)
        } catch {
            host.reset()
            state = .failed(
                CollegeFootballSearchFailurePresentation(
                    title: "No grounded result yet",
                    message: error.localizedDescription,
                    recoverySuggestions: []
                )
            )
        }
    }

    func resetToDiscovery() {
        searchText = ""
        host.reset()
        state = .discovering
        if let activeDiscoveryCardID {
            presentDiscoveryCard(activeDiscoveryCardID)
        }
    }

    func setApplicationActive(_ isActive: Bool) {
        host.setApplicationActive(isActive)
    }
}
