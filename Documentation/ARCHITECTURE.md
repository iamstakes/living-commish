# Baseball Living Host architecture

The application is a single native SwiftUI experience. There is no legacy
reaction composer, fan-memory database, alternate launch mode, App Intent, web
client, server dependency, API key, or remote AI provider.

## Application flow

```text
LivingCommishApp
    ↓
BaseballExperienceRootView
    ├── signed out → Commish-led team and player onboarding cards
    └── signed in  → personalized discovery and search stage
```

`BaseballOnboardingState` owns the demo authentication state and selected team
and player. It persists those explicit choices in `UserDefaults`. Signing out
preserves the choices for a quick demo sign-in; resetting onboarding clears
them and returns to team selection.

`BaseballSearchEnvironment` is the application orchestrator. It owns the
current profile snapshot, discovery cards, query text, search state, result
composition, cancellation, and host behavior. The UI observes one explicit
search state instead of coordinating independent presentation flags.

## Search pipeline

```text
Fan query
    ↓
AdaptiveBaseballQueryInterpreter
    ├── AppleFoundationModelsBaseballQueryInterpreter
    └── DeterministicBaseballQueryInterpreter
    ↓
DefaultBaseballSearchPlanner
    ↓
BaseballDataProviding
    ↓
BaseballHostEditorializing
    ↓
DefaultBaseballResultComposer
    ↓
Result cards on the existing Commish stage
```

Apple Foundation Models classifies intent, entities, time scope, and whether
personal history is required. It does not answer the baseball question or
supply facts. The planner requests structured data from the data provider, and
the result composer builds the UI from that grounded snapshot. When Apple
Intelligence is unavailable, fails, or returns an unknown classification, the
deterministic interpreter handles the same query.

The current `MockBaseballDataService` and discovery service contain
hackathon-quality fixtures, including the Rockies game, standings, Mike
Schmidt, and story preview. Replacing them with a live provider should not
change views, query interpretation, or host control.

## Animated host boundary

Views depend on `AnimatedHostControlling` and generic `HostBehavior` values.
`CommishHostAdapter` maps those behaviors to the current Commish animation
actions. This lets a future team-specific host replace the artwork or behavior
mapping without coupling search code to Rive or PNG details.

```text
HostBehavior
    ↓
CommishHostAdapter
    ↓
AdaptiveCommishController
    ├── validated commish.riv → RiveCommishController
    └── otherwise             → PngSequenceCommishController
```

The PNG controller preloads numerically sorted frames, cancels interrupted
playback, returns one-shot actions to idle, and pauses when the app becomes
inactive. The optional Rive controller activates only after validating the
expected artboard, state machine, and trigger contract.

## Product boundaries

- Authentication is a local demo toggle, not production identity.
- Personalization consists only of explicit team and player selections.
- Apple Intelligence interprets searches; it is not a source of sports truth.
- Baseball data is currently fixture-backed and not live.
- Character playback is reusable infrastructure, not a second product mode.
