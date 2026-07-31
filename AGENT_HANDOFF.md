# College Football Commish — Agent Handoff

Last updated: July 31, 2026

## Why this document exists

This is the technical and operational handoff for the college-football version of Living Commish. It should be given to the next Codex agent together with the new product prompt synthesized from the college-intern conversations.

The new prompt is the authority for product direction. This document describes the working baseline, existing decisions, and safe development workflow. If the prompt explicitly changes a behavior described here, follow the prompt and update this document when the implementation changes.

## Start here

Repository worktree:

```text
/Users/michaeliams/Documents/New project/LivingCommishCFB
```

Git state at handoff:

```text
Branch: codex/college-football
Remote: origin/codex/college-football
Implementation baseline: 46d9c45 (Clone Living Commish for college football)
```

Xcode project and schemes:

```text
CollegeFootballCommish.xcodeproj
CollegeFootballCommish       # app + fast unit tests
CollegeFootballCommishE2E    # focused simulator UI tests
```

App identity:

```text
Product: College Football Commish
Bundle ID: com.takes.collegefootballcommish
Platform: native iOS
Deployment target: iOS 26.0
Swift language mode: Swift 6
Rive dependency: 6.21.1
```

Open this project, not the baseball project:

```sh
cd '/Users/michaeliams/Documents/New project/LivingCommishCFB'
open CollegeFootballCommish.xcodeproj
```

## Repository boundary

The source baseball app still lives at:

```text
/Users/michaeliams/Desktop/LivingCommish
```

It is a separate, clean worktree on `feature/baseball-search`. Do not edit, reset, delete, or build product changes in that directory while working on college football. The college-football app has its own project, target, bundle identifier, domain types, fixtures, schemes, and branch.

Do not reintroduce the removed `hunter-goodman-avatar` sequence. It was an unused 110-frame baseball asset that added approximately 9.8 MB to this clone.

## Product baseline

The app is a personalized college-football discovery and search prototype led by an animated Commish host. Colorado is the current demo profile, not a permanent constraint on the product.

The current demo supports:

- Choosing among 30 featured FBS programs and selecting a current player or legend.
- A Colorado-first profile with Travis Hunter as the default favorite player and Nebraska as the rival.
- A six-card Saturday discovery deck covering rivalry, conference/playoff context, player stories, quiz rewards, and what to watch next.
- A single-tap, full-screen Buffs history Daily Drop that awards a rare Rashaan Salaam card.
- Search for Travis Hunter, Shedeur Sanders, Ashton Jeanty, Charles Woodson, Colorado, and Nebraska.
- A four-image Travis Hunter gallery that opens from a single tap on his search card.
- A Travis Hunter quiz that awards a legendary Hunter card.
- A grounded Travis Hunter versus Ashton Jeanty comparison.
- Visible collection state after rewards are claimed.
- An avatar-choice prompt when a collected sticker supplies an avatar resource.
- Demo reset controls that clear collected rewards and restore the default avatar.

The current Hunter and Salaam rewards intentionally have no replacement-avatar animation. The reusable avatar-selection and reset infrastructure remains in place for future reward art.

## Interaction behaviors to preserve unless the new prompt changes them

- Primary cards respond to one tap. Do not require a second tap because of a nested gesture or transition state.
- Daily Drop opens directly as a full-screen presentation. There is no intermediate detail card.
- Player search results with galleries open the gallery directly.
- A quiz reward must visibly enter the collection before any optional avatar decision is presented.
- Reward and avatar state must be resettable for repeatable demos.
- Search and discovery facts come from providers/models. Views should not invent statistics, schedules, rankings, or outcomes.
- Prototype schedule and playoff content must be labeled as prototype content until connected to a reliable live provider.

## Current demo path

1. Reset the demo and choose Colorado Buffaloes, then Travis Hunter.
2. Show the black-and-gold mountain treatment and the Buffs–Nebraska lead card.
3. Advance through the Big 12 outlook and Hunter player story.
4. Open the Buffs Quiz directly full screen and earn the rare Rashaan Salaam card.
5. Search `Travis Hunter` and open his result card.
6. Browse the four-image two-way archive, take the Hunter quiz, and claim the legendary card.
7. Search `Compare Travis Hunter and Ashton Jeanty` for the comparison flow.
8. Reset collection and avatar state before the next demo.

## Architecture

```text
CollegeFootballExperienceRootView
├── CollegeFootballOnboardingState
├── CollegeFootballSearchEnvironment
│   ├── AdaptiveCollegeFootballQueryInterpreter
│   ├── DefaultCollegeFootballSearchPlanner
│   ├── CollegeFootballDataProviding
│   ├── CollegeFootballHostEditorializing
│   └── DefaultCollegeFootballResultComposer
├── CollegeFootballSearchHomeView
├── CollegeFootballPlayerGalleryExperienceView
└── CollegeFootballDailyDropFullScreenView
```

Responsibilities:

- `CollegeFootballOnboardingState` owns program/player personalization and its persistence.
- `CollegeFootballSearchEnvironment` coordinates discovery, query interpretation, planning, data retrieval, editorial copy, result composition, collection, avatar selection, and presentation state.
- `CollegeFootballQueryInterpreting` converts natural-language text into a typed query.
- `CollegeFootballSearchPlanning` determines which typed modules a query needs.
- `CollegeFootballDataProviding` supplies facts and modules.
- `CollegeFootballHostEditorializing` creates the host's connective copy without manufacturing facts.
- SwiftUI views render typed models and send user actions back into the environment.

The search interpreter is adaptive: it can use Apple Foundation Models when available and falls back to deterministic interpretation. Launching with `--collegeFootball-ui-testing` forces deterministic data and an in-memory sticker store for stable tests.

## Key files

| Area | File |
| --- | --- |
| App entry point | `App/CollegeFootballCommishApp.swift` |
| Personalization and roster provider | `CollegeFootball/App/CollegeFootballPersonalization.swift` |
| Central state/orchestration | `CollegeFootball/App/CollegeFootballSearchEnvironment.swift` |
| Typed domain models | `CollegeFootball/Data/CollegeFootballDataModels.swift` |
| Host behaviors | `CollegeFootball/AnimatedHost/AnimatedHostArchitecture.swift` |
| Host editorial voice | `CollegeFootball/Intelligence/CollegeFootballHostEditorializing.swift` |
| Fixture-backed data/discovery | `CollegeFootball/Mocks/MockCollegeFootballServices.swift` |
| Search interpretation/planning | `CollegeFootball/Search/CollegeFootballSearchServices.swift` |
| Search query/result contracts | `CollegeFootball/Search/CollegeFootballSearchModels.swift` |
| Quiz, sticker, and persistence models | `CollegeFootball/Search/CollegeFootballQuizModels.swift` |
| Root/onboarding/profile UI | `CollegeFootball/Views/CollegeFootballOnboardingView.swift` |
| Discovery and search UI | `CollegeFootball/Views/CollegeFootballSearchHomeView.swift` |
| Player gallery UI | `CollegeFootball/Views/CollegeFootballPlayerGalleryView.swift` |
| Daily Drop/quiz/reward UI | `CollegeFootball/Views/CollegeFootballQuizDropView.swift` |
| Focused architecture tests | `CollegeFootballCommishTests/CollegeFootballArchitectureTests.swift` |
| Host playback tests | `CollegeFootballCommishTests/AnimatedHostPlaybackTests.swift` |
| UI smoke tests | `CollegeFootballCommishUITests/CollegeFootballSearchHomeUITests.swift` |

More detail is available in `Documentation/ARCHITECTURE.md`, `Documentation/DEMO_SCRIPT.md`, `Documentation/APPLE_INTELLIGENCE_SETUP.md`, and `Documentation/RIVE_IMPLEMENTATION.md`.

## Data and factual-grounding rules

The live roster adapter currently reads ESPN's public college-football roster response and merges a small Colorado legends list for the demo. Treat that endpoint as a prototype adapter, not a guaranteed production contract.

The deterministic provider currently has deliberate coverage for:

- Colorado Buffaloes
- Nebraska Cornhuskers
- Travis Hunter
- Shedeur Sanders
- Ashton Jeanty
- Charles Woodson

Do not imply that fixture coverage is league-wide just because the onboarding catalog contains 30 programs.

Historical quiz and Hunter facts were grounded in these primary sources:

- Colorado Athletics — Travis Hunter's 2024 Heisman: <https://cubuffs.com/news/2024/12/14/football-colorados-travis-hunter-wins-heisman-trophy>
- Heisman Trophy Trust — Travis Hunter profile: <https://www.heisman.com/heisman-winners/travis-hunter/>
- Colorado Athletics — Folsom Field: <https://cubuffs.com/facilities/folsom-field/1>
- Colorado Athletics — Rashaan Salaam: <https://cubuffs.com/honors/cu-athletic-hall-of-fame/rashaan-salaam/37>
- Colorado Athletics — 1990 national championship record book: <https://static.cubuffs.com/custompages/football/2025_Record_Book/473-474_1990_national_championship.pdf>
- Pac-12 — July 2026 conference launch and Boise State membership: <https://pac-12.com/news/2026/6/30/general-the-new-pac-12-conference-officially-launches-with-the-addition-of-seven-full-time-members.aspx>

College football schedules, rankings, rosters, conference membership, awards, and eligibility change. Verify time-sensitive additions with current primary sources. Keep exact source URLs near new fixture data or document them here.

## Persistence and demo reset

Production-style demo persistence uses `UserDefaults` for personalization, collected sticker IDs, and the selected avatar. Relevant logic lives in:

- `CollegeFootballOnboardingState`
- `UserDefaultsCollegeFootballStickerStore`
- `CollegeFootballSearchEnvironment.resetStickerDemo()`

The visible reset control uses accessibility identifier `demo-reset-stickers`. It must continue to clear both collection and avatar state. Search-only reset is separate and should not erase a user's collection.

## Build, test, and launch

Use a local derived-data directory so repeat builds stay fast:

```sh
cd '/Users/michaeliams/Documents/New project/LivingCommishCFB'

xcodebuild build \
  -project CollegeFootballCommish.xcodeproj \
  -scheme CollegeFootballCommish \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/CollegeFootballCommish \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test -quiet \
  -project CollegeFootballCommish.xcodeproj \
  -scheme CollegeFootballCommish \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/CollegeFootballCommish \
  CODE_SIGNING_ALLOWED=NO
```

The default scheme contains 13 focused unit tests and intentionally skips UI tests. The cached unit-test round trip was approximately six seconds at handoff.

Run UI tests only when a user flow changes:

```sh
xcodebuild test -quiet \
  -project CollegeFootballCommish.xcodeproj \
  -scheme CollegeFootballCommishE2E \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/CollegeFootballCommish \
  CODE_SIGNING_ALLOWED=NO
```

The three UI smoke scenarios cover the personalized home, Travis Hunter gallery search, and the full-screen Buffs Daily Drop.

For a deterministic manual demo, launch the built bundle with:

```sh
xcrun simctl launch --terminate-running-process booted \
  com.takes.collegefootballcommish \
  --collegeFootball-ui-testing
```

## Stable UI-test hooks

Prefer existing accessibility identifiers over text matching:

```text
collegeFootball-search-field
collegeFootball-search-button
host-presentation-previous
host-presentation-next
discovery-card-discovery-buffs-kickoff
discovery-card-discovery-daily-drop
search-result-card
search-results-previous
search-results-next
player-gallery-start-quiz
daily-drop-start-stories
daily-drop-claim-reward
demo-reset-stickers
```

If a view hierarchy changes, keep the semantic identifier on the tappable element. A previous UI failure came from testing a child identifier that SwiftUI collapsed into its parent button.

## Known prototype boundaries

- Schedule, game, standings, and playoff-path content is fixture-backed; it is not a live 2026 feed.
- The roster adapter is live, but it is not a full college-football data layer.
- Apple Foundation Models availability varies by simulator/device; deterministic fallback is required.
- The authenticated Rive project is not exported into a complete `commish.riv` runtime asset. The app intentionally uses the checked-in PNG fallback.
- The Commish host art is inherited from the original prototype and has not yet been redesigned specifically for college football.
- The avatar replacement mechanism exists, but current college-football reward cards do not include animated avatar resources.
- Fixture coverage is intentionally narrow and should expand only with grounded data.

## Development guardrails

- Preserve the separate college-football product identity and bundle ID.
- Keep domain names under `CollegeFootball`; do not revive `Baseball` types or copy.
- Keep the default scheme fast. Add focused model/service tests for new logic and only essential UI smoke coverage.
- Do not add large frame sequences or duplicate media without confirming they are used and appropriate for a mobile bundle.
- Preserve single-tap navigation and direct full-screen presentation behavior.
- Do not hide a newly earned reward behind a transition; make collection state visible.
- Keep demo reset complete and reliable.
- Inspect the simulator after material visual changes, not only compiler output.
- Preserve unrelated user changes if the worktree is dirty.
- Use current, primary sources for time-sensitive college-football facts.

## First-turn checklist for the next agent

1. Read the accompanying product prompt completely.
2. Read this handoff and `Documentation/ARCHITECTURE.md`.
3. Confirm `git status -sb` and remain on `codex/college-football` unless the user requests a new branch.
4. Run the fast unit suite before modifying the architecture.
5. Launch the deterministic demo and inspect the current baseline.
6. Translate the new prompt into concrete changes while preserving the boundaries above unless explicitly superseded.
7. Run focused tests and visually verify affected flows.
8. Leave the original baseball worktree untouched.
