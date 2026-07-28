import Foundation
import Observation

@MainActor
struct BaseballSearchDependencies {
    let profile: BaseballFanProfileSnapshot
    let queryInterpreter: any BaseballQueryInterpreting
    let planner: any BaseballSearchPlanning
    let dataProvider: any BaseballDataProviding
    let discoveryProvider: any BaseballDiscoveryProviding
    let hostEditor: any BaseballHostEditorializing
    let resultComposer: any BaseballResultComposing
    let host: any AnimatedHostControlling

    static func prototype(bundle: Bundle = .main) -> BaseballSearchDependencies {
        BaseballSearchDependencies(
            profile: MockMichaelProfile.value,
            queryInterpreter: DeterministicBaseballQueryInterpreter(),
            planner: DefaultBaseballSearchPlanner(),
            dataProvider: MockBaseballDataService(),
            discoveryProvider: MockBaseballDiscoveryService(),
            hostEditor: DeterministicBaseballHostEditor(),
            resultComposer: DefaultBaseballResultComposer(),
            host: LegacyCommishHostAdapter(bundle: bundle)
        )
    }
}

@MainActor
@Observable
final class BaseballSearchEnvironment {
    let profile: BaseballFanProfileSnapshot
    let host: any AnimatedHostControlling

    var searchText = ""
    private(set) var state: BaseballSearchExperienceState = .discovering
    private(set) var discoveryCards: [BaseballDiscoveryCard] = []
    private(set) var activeDiscoveryCardID: String?
    private(set) var discoveryError: String?

    @ObservationIgnored private let queryInterpreter: any BaseballQueryInterpreting
    @ObservationIgnored private let planner: any BaseballSearchPlanning
    @ObservationIgnored private let dataProvider: any BaseballDataProviding
    @ObservationIgnored private let discoveryProvider: any BaseballDiscoveryProviding
    @ObservationIgnored private let hostEditor: any BaseballHostEditorializing
    @ObservationIgnored private let resultComposer: any BaseballResultComposing

    init(dependencies: BaseballSearchDependencies) {
        profile = dependencies.profile
        host = dependencies.host
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
                BaseballSearchFailurePresentation(
                    title: "What should we search?",
                    message: BaseballSearchArchitectureError.emptyQuery.localizedDescription,
                    recoverySuggestions: ["Aaron Judge", "Games tonight", "Who should I watch?"]
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
                throw BaseballSearchArchitectureError.needsRefinement(
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
                BaseballSearchFailurePresentation(
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
