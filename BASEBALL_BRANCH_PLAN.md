# Baseball Living Host branch plan

## Purpose and branch boundary

This document is the Phase 1 audit and implementation plan for **Baseball Living Host**. The product goal is a search-first, visual baseball experience with an animated guide—not a chat transcript.

- Planning branch: `feature/baseball-search`
- Native baseline: `d9d66c1` (`Add native iOS Living Commish prototype`)
- Minimum target: iOS 26.0 with Swift 6
- Current verification device: iPhone 17 Pro simulator

No baseball implementation is included in this phase. The existing Living Commish source, behavior, assets, tests, and web prototype remain unchanged.

## Current Living Commish architecture

### Application composition

`LivingCommishApp` creates:

- one SwiftData `ModelContainer`
- one observable `AppEnvironment`
- one `CommishStageView`

`AppEnvironment` is the current composition root and orchestration layer. It owns the animation controller, intelligence provider, input and response state, presentation flags, feedback state, demo tasks, event log, and access to `CommishMemoryStore`.

This is effective for a focused prototype, but it mixes product state, UI state, demo tooling, intelligence orchestration, and persistence. Baseball search should keep a single observable screen model while moving those responsibilities behind injected protocols.

### Current reaction pipeline

```text
Fan event text
    ↓
FanEventSignalExtractor
    ↓
ReactionBriefBuilder
    ↓
ReactionPolicy
    ↓
AdaptiveCommishIntelligenceProvider
    ├── AppleFoundationModelsCommishProvider
    └── DeterministicCommishProvider
    ↓
CommishReactionValidator
    ↓
MemoryPolicy / CommishMemoryStore
    ↓
AdaptiveCommishController
    ├── RiveCommishController
    └── PngSequenceCommishController
    ↓
CommishStageView
```

Normal Swift owns semantic classification, fan relationship, constrained action and emotion, validation, and persistence. Apple Foundation Models supplies only short character copy. This is the correct trust boundary to retain: a language model must not invent scores, schedules, statistics, standings, player status, or personal history.

### Animation system

`CommishControlling` isolates the UI from renderer details. It exposes readiness, current action, renderer identity, a PNG frame or native renderer view, fallback details, playback, reset, and application activity.

`AdaptiveCommishController` selects:

- validated Rive at runtime when `commish.riv` satisfies the full contract
- predecoded PNG sequences otherwise

The PNG renderer loads 420 transparent frames, sorts them numerically, decodes them off the main actor, caches them, advances at 24 fps, cancels superseded playback, and returns one-shot actions to idle.

The Rive adapter requires:

- artboard `Commish`
- state machine `CommishSM`
- a default bound view model
- `pointRight`, `sadShrug`, `wave`, and `foamFinger` triggers

The Rive asset is not currently exported, so PNG is the real working renderer. Rive remains an optional validated upgrade path.

### Current state machines

There are three related state systems:

1. **Application reaction state** in `AppEnvironment`: idle input, generating, showing a result, awaiting feedback, corrected/approved, memory sheet, and demo playback. These states are represented by several booleans and optionals rather than one explicit enum.
2. **Renderer playback state** in `PngSequenceCommishController`: requested action, current action/frame, loop or one-shot, automatic return to idle, active/background pause.
3. **Rive animation state** in the asset contract: `Idle` transitions to a triggered one-shot and returns to `Idle` on completion.

Baseball search needs an explicit experience state that is independent of host animation:

```text
discovering
    ↓ search submitted
interpreting
    ↓
loading modules
    ↓
presenting results
    ↘ recoverable error
```

The host should react to those states through commands. The host must not become the source of screen navigation or search truth.

### Prompt generation and intelligence

`ReactionBriefBuilder` creates a compact semantic brief from:

- event intent
- topic
- actor and target
- sentiment valence
- emotional arousal
- anticipation
- known tradition
- favorite and rival team relationship
- likely fan impact
- preferred tone
- learned policy adjustments

`AppleFoundationModelsCommishProvider` uses a short-lived on-device session and asks for three concise candidates. Swift sanitizes, rejects unsupported claims and strange figurative language, scores the candidates, and falls back to a deterministic local editor. It uses string output with permissive content transformations because the verified simulator's default safety-model path fails before generation.

`DeterministicCommishProvider` provides topic-specific local copy and rotates alternatives. Both providers consume the same `ReactionBrief`, so fallback retains personalization.

The current topic taxonomy and editorial instructions are football/Takes-specific. They should not be expanded into an all-purpose baseball search engine. Baseball needs a separate query interpretation and result-planning layer.

### Memory and learning

SwiftData is the source of truth. Current models are:

- `FanProfile`
- `CommishMemory`
- `ReactionFeedback`
- `LearnedReactionPreference`

`CommishMemoryStore` enforces one canonical profile, bounded recurring memories, deduplication, a maximum of 200 feedback records, bounded preference weights, and full deletion.

Learning is explicit. Approval slightly reinforces an action/emotion pair; correction penalizes the prior pair and reinforces the selected pair for matching feature keys. Hard semantic constraints still prevent unsafe combinations.

This feedback design is reusable. The stored football profile schema is not.

### Current UI

`CommishStageView` is a vertically scrolling reaction composer containing:

- title and memory access
- renderer/intelligence/mood/state diagnostics
- response bubble
- explicit feedback controls
- animated character
- event text field and generate button
- one-tap scenarios
- demo/developer controls and event log

This screen is intentionally reaction-centric and visually reads as conversational. It should remain available for Living Commish validation, but it should not become the baseball home screen.

## Reusable systems

Reuse directly or behind adapters:

- SwiftUI and Observation composition
- `CommishControlling` behavior contract as the basis of a generic host contract
- adaptive Rive/PNG renderer selection
- frame preloading, numerical sorting, cancellation, lifecycle pausing, and idle return
- constrained action/emotion planning
- Apple Foundation Models availability, retry, session rotation, and transparent local fallback
- deterministic local editorial fallback
- generated-line sanitization and factual claim rejection
- SwiftData ownership of visible, editable memory
- bounded explicit-feedback learning
- dependency injection through protocols
- accessibility identifiers and unit/UI testing patterns
- debug visibility for provider and renderer status

Reuse with baseball-specific replacements:

- semantic brief construction
- action/emotion policy features
- fan profile and memory models
- host instructions and deterministic copy
- one-tap demo fixtures
- App Intent vocabulary
- result validation

Keep unchanged during early phases:

- existing Living Commish views and tests
- current Commish assets
- current reaction providers
- existing React/Vite prototype

## Proposed baseball architecture

### Architectural principles

1. Search is the root interaction, never a transcript.
2. Verified data creates result modules; language models may interpret or phrase but never manufacture data.
3. Every result module is typed, visual, independently testable, and carries provenance.
4. Discovery and search use the same card models so the experience feels continuous.
5. Host animation is commanded by experience state and result meaning, not coupled to a specific character.
6. Michael's mock profile and all mock MLB data remain isolated and replaceable.
7. Facts, opinions, and predictions are labeled in the domain model and presentation.
8. Existing Living Commish continues to compile and remains testable.

### Proposed data flow

```text
Search text or discovery request
    ↓
BaseballQueryInterpreting
    ↓
BaseballSearchIntent + recognized entities
    ↓
BaseballSearchPlanning
    ↓
BaseballDataProviding
    └── MockBaseballDataService initially
    ↓
Verified BaseballFact values with source and freshness
    ↓
BaseballResultComposing
    ├── typed result modules
    ├── "Why this matters" personalization
    └── related searches / watch next
    ↓
BaseballHostEditorializing
    ├── Apple on-device phrasing
    └── deterministic local phrasing
    ↓
BaseballSearchExperienceModel
    ├── BaseballSearchHomeView
    ├── BaseballSearchResultsView
    └── AnimatedHostControlling
```

### Generic animated host

Introduce a domain-neutral host boundary:

```swift
protocol AnimatedHostControlling: AnyObject {
    var descriptor: AnimatedHostDescriptor { get }
    var isReady: Bool { get }
    var currentBehavior: HostBehavior { get }
    var rendererName: String { get }
    var renderedContent: HostRenderedContent { get }
    var fallbackReason: String? { get }

    func perform(_ behavior: HostBehavior)
    func reset()
    func setApplicationActive(_ isActive: Bool)
}
```

Planned behavior vocabulary:

- idle
- greet
- think
- celebrate
- explain
- concerned
- tease
- interrupt

`AnimatedHostDescriptor` will provide display name, accessibility identity, editorial persona, asset manifest, supported behaviors, and disclosure language. The UI will render `HostRenderedContent` and will not reference Commish, Hunter Goodman, Rive trigger names, or PNG directories.

The first implementation will wrap the current `AdaptiveCommishController` with `LegacyCommishHostAdapter`. Hunter can later supply a new descriptor and renderer adapter without changing search views.

The future Hunter-inspired guide must be labeled as a fictional animated baseball guide. It must not claim to be Hunter Goodman, quote him, or present generated speech as his real views.

### Search domain

`BaseballSearchIntent` should cover the prototype's priority requests:

- entity lookup
- team lookup
- games tonight
- player recommendation
- player comparison
- availability explanation
- missed-games recap
- standings or Wild Card impact
- personal attendance history
- watch-next recommendation

`BaseballSearchQuery` will contain raw text, normalized intent, player/team entities, time range, comparison entities, personal-history requirement, and ambiguity.

`BaseballResultModule` will be a typed enum, not a text blob:

- host reaction
- player
- team
- game
- live score
- schedule
- standings
- highlight
- Statcast visualization
- historical comparison
- fantasy impact
- ticket opportunity
- personal fan memory
- why this matters
- related searches
- watch next

Each factual payload will include a source label and `asOf` timestamp. Opinion and prediction payloads will carry an explicit classification so the UI can distinguish them.

### Search experience state

Use one explicit screen state:

```swift
enum BaseballSearchExperienceState {
    case discovering
    case interpreting(query: String)
    case loading(plan: BaseballSearchPlan)
    case presenting(BaseballSearchExperience)
    case failed(SearchFailurePresentation)
}
```

Host behavior maps from state transitions and result meaning:

- discovering → idle or greet
- interpreting → think
- positive favorite-team result → celebrate
- explanation/comparison → explain
- injury or elimination → concerned
- rival setback → tease
- breaking/high-priority moment → interrupt

Host behavior is presentation metadata. It cannot change the underlying search plan or factual result modules.

### Discovery

`BaseballDiscoveryProviding` will return personalized `BaseballDiscoveryCard` values using the same data contracts as search results.

Every card must include:

- a clear visual subject
- one timely claim
- why Michael should care
- a destination/search query
- provenance and freshness

Initial mock discovery:

- Rockies game tonight
- emerging player to watch
- relevant Wild Card movement
- a Dodgers result with rivalry relevance
- condensed game recommendation
- a baseball-history story connected to Michael's interests or attendance

### Mock fan and mock services

Michael's fixture will live in a single mock-only file and will not be scattered through views or prompts.

Profile:

- name: Michael
- favorite team: Colorado Rockies
- interests: emerging players, standings, playoff races, baseball history, condensed games, great stories
- multiple attended MLB stadiums
- frequent playoff-implication searches

Mock services will expose realistic but clearly fixture-labeled data. No UI string will imply that mock schedules, standings, injuries, or Statcast values are live.

Later, real MLB services should replace the mock implementation by conforming to the same protocols. Views and result composition should not change.

### Baseball memory and personalization

Add baseball-specific SwiftData models rather than expanding `FanProfile` with unrelated fields:

- `BaseballFanProfile`
- `FavoritePlayer`
- `StadiumVisit`
- `BaseballSearchHistoryEntry`
- `BaseballInterestSignal`
- `BaseballHostFeedback`

Initial personalization uses the explicit Michael fixture. Later learning may use:

- explicit favorite/team/player changes
- saved or dismissed discovery cards
- explicit host reaction feedback
- searches and result-module opens
- completed watch actions

Passive behavior must be treated as a weak signal, not certainty. Personal history must remain inspectable and erasable. Sensitive location or purchase details should not be sent to a language model unless strictly required and explicitly represented in the search plan.

### Intelligence boundary

Use Apple Foundation Models for:

- natural-language intent interpretation when deterministic parsing is ambiguous
- short host reactions grounded in supplied facts
- concise "why this matters" phrasing
- related-search wording

Do not use a model for:

- schedules, scores, standings, player status, statistics, or historical facts
- deciding whether mock data is current
- selecting ticket offers
- inferring attendance, purchases, fantasy ownership, or location
- unreviewed predictions
- speaking as a real player

The local deterministic implementation must support every demo query so the experience works without Apple Intelligence.

## Files to add

Proposed paths may be refined during Phase 2, but responsibilities should remain separated.

```text
Baseball/
  App/
    BaseballSearchEnvironment.swift
    BaseballSearchExperienceState.swift
  AnimatedHost/
    AnimatedHostControlling.swift
    AnimatedHostDescriptor.swift
    HostBehavior.swift
    LegacyCommishHostAdapter.swift
  Search/
    BaseballSearchModels.swift
    BaseballQueryInterpreting.swift
    BaseballSearchPlanning.swift
    BaseballResultComposing.swift
    DeterministicBaseballQueryInterpreter.swift
    AppleBaseballQueryInterpreter.swift
  Data/
    BaseballDataProviding.swift
    BaseballFact.swift
    MockBaseballDataService.swift
  Discovery/
    BaseballDiscoveryProviding.swift
    MockBaseballDiscoveryService.swift
  Intelligence/
    BaseballHostEditorializing.swift
    AppleBaseballHostEditor.swift
    DeterministicBaseballHostEditor.swift
  Memory/
    BaseballFanModels.swift
    BaseballMemoryStore.swift
  Mocks/
    MockMichaelProfile.swift
    MockBaseballFixtures.swift
  Views/
    BaseballSearchHomeView.swift
    BaseballSearchField.swift
    AnimatedHostView.swift
    BaseballDiscoveryRail.swift
    BaseballSearchResultsView.swift
    ResultModules/
      PlayerResultCard.swift
      TeamResultCard.swift
      GameResultCard.swift
      StandingsResultCard.swift
      HighlightResultCard.swift
      StatcastResultCard.swift
      ComparisonResultCard.swift
      WhyThisMattersCard.swift
      RelatedSearchesCard.swift
      WatchNextCard.swift
BaseballLivingHostTests/
  BaseballQueryInterpreterTests.swift
  BaseballSearchPlannerTests.swift
  BaseballDiscoveryTests.swift
  BaseballResultComposerTests.swift
  AnimatedHostAdapterTests.swift
BaseballLivingHostUITests/
  BaseballSearchHomeUITests.swift
  BaseballStructuredResultsUITests.swift
  BaseballPersonalizationUITests.swift
```

## Files to modify

- `App/LivingCommishApp.swift`
  - Add a small experience composition boundary and baseball SwiftData models.
  - Default the baseball branch to the search experience.
  - Preserve a launch argument or scheme for the existing Commish experience and tests.
- `LivingCommish.xcodeproj/project.pbxproj`
  - Add baseball groups, source membership, and test targets or test files.
- `LivingCommish.xcodeproj/xcshareddata/xcschemes/LivingCommish.xcscheme`
  - Preserve current test coverage and add explicit launch configuration if needed.
- `Animation/AdaptiveCommishController.swift`
  - Only if the legacy adapter cannot provide all generic rendered content without a minimal exposure change.
- `Models/CommishModels.swift`
  - Avoid renaming initially; add no baseball domain cases here.
- `README.md`
  - Add baseball branch run instructions, mock-data disclosure, and architecture entry points.
- `Documentation/ARCHITECTURE.md`
  - Keep the Living Commish document accurate; link to a separate baseball architecture document.
- `Resources/`
  - Add only licensed or generated baseball fixtures and visual assets, with provenance documented.

Avoid modifying the current Commish providers, reaction policy, memory store, and views until generic adapters are compiling and covered. Do not perform a broad symbol rename.

## Implementation phases and verification gates

### Phase 1 — Audit

Deliverable:

- this document
- isolated `feature/baseball-search` branch
- unchanged Living Commish baseline build

Gate:

- native build passes
- existing unit tests pass
- no baseball runtime code added

### Phase 2 — Architecture

Deliverables:

- generic animated-host contracts
- baseball search/data/discovery/editorial protocols
- typed search intents, plans, facts, result modules, and experience state
- isolated Michael fixture
- dependency container with mock implementations
- legacy Commish host adapter

Gate:

- build after each contract group
- unit tests prove mock and production-facing implementations are swappable
- legacy Commish tests remain green
- no search UI yet

### Phase 3 — Search home

Deliverables:

- search-first root screen
- large animated host
- large native search field
- empty state driven by personalized discovery, not chat history
- current iOS Liquid Glass materials, depth, motion, whitespace, and accessibility

Gate:

- launch immediately reads as search
- no transcript or message composer
- keyboard, Dynamic Type, VoiceOver labels, loading, empty, and error states work
- visual verification on iPhone 17 Pro simulator

### Phase 4 — Discovery

Deliverables:

- mock personalized discovery service
- visual discovery cards for Michael
- clear "why you should care" on every card
- provenance/freshness disclosure

Gate:

- deterministic ordering for UI tests
- each card opens a structured result or fills a search
- no generic news-feed presentation

### Phase 5 — Structured search results

Deliverables:

- typed modular result experience
- dedicated layouts for player, team, game, comparison, recap, standings impact, personal history, and recommendation queries
- related search and watch-next modules
- fact/opinion/prediction labeling

Gate:

- all example queries in the brief have fixture-backed results
- no response is a paragraph wall
- unsupported or ambiguous queries produce helpful refinements, not invented facts
- snapshot or UI coverage for each module family

### Phase 6 — Animation integration

Deliverables:

- generic host view/controller connection
- host reactions to search lifecycle and result meaning
- legacy Commish assets as the default baseball guide
- clean descriptor-based replacement point for Hunter

Gate:

- UI contains no Commish-specific host assumptions
- every supported behavior has a tested fallback
- one-shot behavior returns to idle
- background/foreground and rapid-search cancellation work

### Phase 7 — Memory and personalization

Deliverables:

- baseball-specific SwiftData models and store
- editable Michael profile
- recent searches, saved interests, stadium history, and explicit feedback
- erase/reset controls
- personalization incorporated into discovery and "why this matters"

Gate:

- model transcript is never canonical memory
- mock data and learned data are visibly distinguishable
- deletion removes profile, history, feedback, and derived signals
- tests cover deduplication, limits, and personalization effects

### Phase 8 — Polish

Deliverables:

- motion and transition pass
- video-first highlight presentation
- loading skeletons and graceful offline/mock states
- demo script and reset flow
- accessibility and performance pass
- final architecture and handoff documentation

Gate:

- clean build and unit suite
- focused UI suite for the end-to-end demo
- physical-device check if available
- no claim of live MLB data where fixtures are used

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| No live MLB service is currently integrated | Mock results could be mistaken for current facts | Label fixtures and freshness; keep all facts behind `BaseballDataProviding` |
| Scope expands into every possible baseball query | Prototype becomes a dense dashboard or shallow demo | Prioritize the supplied example-query set and reusable module families |
| Generic-host refactor breaks Living Commish | Existing experience regresses | Add an adapter first, preserve source, compile both experiences, keep legacy UI tests |
| Hunter-inspired host is perceived as the real player speaking | Trust, likeness, and rights problem | Use fictional-guide disclosure; never impersonate, quote, or assert real opinions |
| MLB marks, video, player likenesses, and footage require rights | Demo assets may be unusable outside a controlled prototype | Document provenance and use approved, licensed, or generated placeholder assets |
| Apple model invents live facts | Search becomes untrustworthy | Only pass verified facts; validate outputs; use the model for interpretation and phrasing only |
| Foundation Models behavior differs between simulator and device | Apple path may fail during demo | Retain deterministic parity, visible provider status, retry, and local fallback |
| Current PNG renderer preloads 420 frames | Memory and launch latency may grow with more hosts | Keep one interim host; later use Rive or lazy per-behavior loading after measurement |
| Rive runtime export is not currently available on the account | Generic renderer upgrade may be blocked | Keep PNG as a first-class path; do not make Rive a search milestone dependency |
| Current fixed action set does not include think or interrupt | Host cannot express the full baseball lifecycle | Map unsupported behaviors through descriptor fallbacks until new assets exist |
| Current `AppEnvironment` relies on multiple booleans | Search cancellation and presentation can drift | Introduce one explicit search experience enum and isolate tasks in a baseball environment |
| Personal MLB data is powerful and sensitive | Over-personalization could feel invasive | Make sources visible, use explicit controls, minimize prompt context, and provide full erase |
| "Latest Apple design" APIs may change across SDKs | Visual code may not compile or degrade consistently | Implement and build against the installed Xcode 26.4.1 SDK; wrap optional effects with fallbacks |
| Existing UI automation has shown simulator/XCTest stalls | Full-suite signals may be noisy | Keep deterministic focused UI tests and distinguish simulator infrastructure stalls from assertions |

## Assumptions

- `d9d66c1` is the correct native Living Commish baseline.
- This phase ends after audit, planning, branch creation, and baseline verification.
- Real MLB API credentials, schemas, and usage rights are not currently available.
- Mock data is acceptable for the hackathon if it is isolated and clearly disclosed.
- Michael is a prototype fixture, not production account data.
- The existing Commish animation is the interim baseball host.
- Hunter-inspired art and animation will arrive later through a descriptor/adapter, not a UI rewrite.
- The product targets iOS 26 and the installed Xcode 26.4.1 environment.
- The demo must remain useful without a network, backend, API key, Rive export, or Apple Intelligence.
- Audio, speech synthesis, push notifications, live video streaming, commerce checkout, and production authentication are outside the initial build unless separately authorized.
- Baseball predictions, if added, will be labeled and grounded in supplied model inputs rather than presented as facts.

## Phase 1 decision

Proceed to Phase 2 only after review of this plan. The first implementation change should establish generic host and baseball search contracts with mock dependencies while leaving Living Commish behavior intact.

## Phase 2 implementation status

Phase 2 was approved and completed on July 27, 2026.

Implemented:

- character-neutral `AnimatedHostControlling`, `AnimatedHostDescriptor`, and `HostBehavior` contracts
- `LegacyCommishHostAdapter`, allowing search UI to use the current animation without Commish-specific knowledge
- typed baseball facts with claim classification, provenance, freshness, and explicit mock-data disclosure
- typed player, team, game, standings, highlight, Statcast, comparison, personal-memory, related-search, and watch-next modules
- explicit baseball query, search-plan, search-experience, discovery-card, and experience-state models
- deterministic interpretation and modular planning for every priority query in the product brief
- replaceable query, planning, data, discovery, editorial, composition, and host dependencies
- isolated Michael profile and deterministic prototype MLB fixtures
- a complete `BaseballSearchEnvironment` orchestration pipeline without adding a search screen
- seven focused architecture tests

Intentionally deferred:

- changing the app root or existing Living Commish UI
- baseball SwiftData persistence
- Apple Foundation Models baseball interpretation/editorial
- production MLB services
- baseball search and result views
- Hunter-inspired assets

Verification:

- native build passed
- 27 of 27 unit tests passed: 7 baseball architecture tests and 20 existing Living Commish tests
- focused Living Commish launch UI test passed

The next incremental phase is Phase 3: build the search-first home screen against these contracts while preserving the legacy launch path for regression tests.

## Phase 3 implementation status

Phase 3 was approved and completed on July 27, 2026.

Implemented:

- Baseball Living Host is the default app experience on this branch
- `--legacy-commish` preserves an explicit manual launch path for Living Commish
- existing `--ui-testing` launches remain mapped to Living Commish so its regression suite is unchanged
- `--baseball-ui-testing` provides an isolated deterministic launch path for the new experience
- a search-first home with the search field before the animated guide in the visual hierarchy
- native iOS 26 Liquid Glass containers and buttons, dark spatial depth, reduced-motion support, lifecycle handling, and VoiceOver identifiers
- a character-neutral `AnimatedHostView` rendering the current PNG/Rive adapter without search UI knowledge of Commish actions or assets
- a personalized Michael/Rockies identity and discovery empty state
- explicit prototype-data and fictional-guide disclosures
- visual loading, result, empty, and recoverable-error states
- a modular result overview with host opinion, typed result previews, why-it-matters content, and related search actions

Intentionally deferred:

- live MLB data and production source attribution
- dedicated full layouts for every result-module family
- baseball-specific SwiftData persistence and feedback
- Apple Foundation Models baseball query interpretation/editorial
- replacement host art

Verification:

- native iOS 26.4 simulator build passed
- 28 of 28 unit tests passed: 8 baseball architecture tests and 20 existing Living Commish tests
- 2 of 2 Baseball Living Host UI tests passed
- focused legacy Living Commish launch UI test passed
- visual inspection on the iPhone 17 Pro simulator confirmed that search is above the fold and the home does not read as a transcript

The next incremental phase is Phase 4: deepen the personalized discovery rail, card destinations, and provenance/freshness presentation without introducing a generic news feed.

## Post-Phase 3 search trust hardening

The first manual profile-query test exposed two invalid assumptions: unknown intent was allowed to render recovery instructions as a result, and the result UI labeled every host line as opinion regardless of claim type.

The hardening pass:

- adds explicit favorite-team and favorite-player intents with multiple supported phrasings
- answers profile lookups directly from the injected fan profile
- labels grounded profile answers as facts rather than host opinions
- routes unknown queries to refinement/error state instead of result presentation
- prevents mock player or team fixtures from being silently substituted for unsupported favorites

Verification:

- 31 of 31 unit tests passed
- all 3 Baseball Living Host UI tests passed
- the focused legacy Living Commish launch UI test passed
- the exact query `What is my favorite team?` was visually verified to render `FACT — Your favorite team is the Colorado Rockies.`
