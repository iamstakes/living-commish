# Apple Intelligence and Foundation Models

## Current local verification

The project targets iOS 26 and imports Apple's `FoundationModels` framework from the installed iOS 26.4 SDK. It was built with Xcode 26.4.1 (17E202) and Swift 6.3.1.

`SystemLanguageModel.default.availability` was checked in a running iPhone 17 Pro simulator on this Apple M3 Mac. The model reported available. A minimal live diagnostic then exposed an iOS 26.4.1 simulator-runtime failure in the default guardrail path: Apple's 300M safety-model asset failed to decode its own `thoughtContents` field before the 3B language model could answer.

The same live diagnostic succeeds with Apple's documented
`permissiveContentTransformations` guardrail and a string response. The installed app now uses that path and has completed normal, personalized Penn State and Ohio State generations while the UI reported `Intelligence: Apple Foundation Model`. This verifies the on-device model path rather than compilation alone.

The known physical iPhone is currently offline, so device execution remains unverified. A physical test requires an Apple Intelligence-capable iPhone, iOS 26 or later, Apple Intelligence enabled with its model ready, a signing team, and the device connected and trusted.

Official starting points:

- [Foundation Models framework](https://developer.apple.com/documentation/foundationmodels)
- [SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)
- [Permissive content transformations](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails/permissivecontenttransformations)
- [Generating Swift data with guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-with-guided-generation-and-tools)

## Runtime selection

`AppleFoundationModelsCommishProvider` maps the installed SDK's availability states to a readable status:

- available
- device not eligible
- Apple Intelligence not enabled
- model not ready
- unknown future unavailability

`AdaptiveCommishIntelligenceProvider` uses Apple only for `available`. Every other state selects the personalized local provider. If an available session later fails, refuses, exceeds context, returns invalid output, or is already responding, it creates a fresh session and retries once. After a second failure, the same semantic brief runs locally, the UI shows an explicit fallback notice, and the raw reason is logged. Cancellation never falls through to another provider.

## Simulator safety-model workaround

Apple documents `permissiveContentTransformations` for transforming user-provided text into string output. The documentation also states that non-string structured outputs continue to use the default guardrail behavior. For that reason, routing the existing `@Generable CommishReaction` through the permissive model does not avoid this simulator decoder failure.

`AppleFoundationModelsCommishProvider` therefore asks Apple only for spoken-string candidates. Normal Swift derives the constrained action and emotion from `ReactionBrief`, including any explicit on-device feedback weights, disables model-authored memory on this path, strips leaked control labels, ranks candidates for topic relevance and required personalization, and validates that the final line is nonempty and at most 18 words. This is a deliberate hybrid boundary: Apple supplies prose; deterministic, inspectable app code owns behavior and persistence.

If Apple returns text but every candidate violates the editorial contract, the request does not masquerade as an Apple system failure. The provider applies the same brief through its deterministic local editor and reports `Apple + local editor`. Actual Apple runtime errors still receive one fresh-session retry and then surface the explicit Personalized local fallback notice.

`CommishReaction`, `CommishAction`, `CommishEmotion`, and `MemoryDecision` still use `@Generable` so the domain model remains compatible with guided generation when Apple's default guardrail path is healthy. They are not passed to the current simulator generation call.

The session instructions require direct, modern sports-commissioner language, prohibit live-fact invention, and explicitly disallow model-authored metaphors, idioms, rhetorical questions, affected football units, and future outcomes. Opinion questions use a separate reasoning-and-rewrite pass with multiple candidates; Swift rejects generic consequences, unsupported claims, control-label leakage, missing personalization, and invalid length.

## Session lifecycle

Only one request uses a session at a time. The provider keeps prompts compact, includes only `ReactionBriefBuilder` output, and replaces the session after six responses. “Reset Model Session” immediately creates a fresh session and also resets local response rotation.

The transcript is short-lived generation context. It is never treated as durable fan memory. SwiftData remains the visible, editable source of truth.

When the app backgrounds, character playback pauses. An in-flight generation may complete or cancel according to Foundation Models behavior; either outcome is handled safely and does not bypass result validation.

## Common problems

- **Device not eligible:** use a supported Apple Intelligence device or rely on Personalized local.
- **Apple Intelligence not enabled:** enable it in Settings and wait for the system model to become available.
- **Model not ready:** keep the device powered and allow system model preparation to finish; the app continues locally meanwhile.
- **Generation refusal or guardrail:** the adaptive provider retries once, then logs the failure and generates a personalized local reaction.
- **`thoughtContents` decoding failure in the simulator:** confirm string output uses `permissiveContentTransformations`; structured output still takes the affected default guardrail path.
- **Context limit:** reset the session; the app also rotates sessions automatically and sends only relevant context.
- **Concurrent response:** the app disables submission and rejects a second request while one is running.
- **Invalid generated response:** Swift validation rejects it and the adaptive provider falls back.
- **Simulator differs from device:** rely on the status displayed by the running target and complete a signed physical-device pass before shipping.

## Physical-device check

1. Open `LivingCommish.xcodeproj` in Xcode.
2. Select the LivingCommish target, Signing & Capabilities, and choose your team.
3. Connect and trust an Apple Intelligence-capable iPhone running iOS 26 or later.
4. Confirm Apple Intelligence is enabled and its model is ready in Settings.
5. Choose the iPhone as the run destination and press Run.
6. Confirm the status pill says `Intelligence: Apple Foundation Model`.
7. Trigger Cracked Helmet and Lost Streak, then verify a constrained response, matching animation, idle return, and editable Memory sheet.
