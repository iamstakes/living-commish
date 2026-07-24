# Living Commish architecture

Living Commish is a native SwiftUI prototype. It has no server dependency, API key, remote AI provider, audio stack, or live-sports feed. All fan context and memory stay in the app's local SwiftData store.

## Reaction pipeline

```text
Fan event
    ↓
FanEventSignalExtractor — intent, valence, arousal, anticipation, and known traditions
    ↓
ReactionBriefBuilder — topic, actor, fan relationship, impact, and learning features
    ↓
ReactionPolicy — scores allowed action/emotion pairs using semantics plus learned local weights
    ↓
AdaptiveCommishIntelligenceProvider
    ├── AppleFoundationModelsCommishProvider
    └── DeterministicCommishProvider — consumes the same semantic brief
    ↓
CommishReactionValidator — ≤18 words and constrained Swift enums
    ↓
MemoryPolicy — optional, grounded, nonsensitive, deduplicated candidate
    ↓
AdaptiveCommishController
    ├── RiveCommishController
    └── PngSequenceCommishController
    ↓
SwiftUI stage, response bubble, status indicators, and event log
    ↓
Explicit Yes/Correct feedback
    ↓
SwiftData feedback history + bounded learned weights ──→ ReactionPolicy
```

The Apple model returns only a spoken line. It cannot choose character behavior, write memory, access files, access a network, or execute arbitrary functions. Normal Swift derives the constrained `CommishAction` and `CommishEmotion` from the semantic brief, validates the line, applies the memory policy, and chooses the renderer action.

## Renderer isolation

`CommishControlling` is the UI-facing interface. Both renderers publish the same readiness, action, status, frame/view, reset, and app-activity controls.

The PNG renderer numerically sorts, decodes, and caches every frame before playback. A task advances cached images at the configured frame rate. New actions cancel the previous task, one-shots return to idle, and animation work stops while the scene is inactive.

The Rive renderer is optional. It loads `commish.riv` using Rive's Swift-first Apple API and becomes active only after validating:

- artboard `Commish`
- state machine `CommishSM`
- default data-bound view model
- trigger properties `pointRight`, `sadShrug`, `wave`, and `foamFinger`

Any failure leaves the PNG renderer active and records the reason in the development event log.

## Intelligence isolation

`CommishIntelligenceProviding` has two implementations. The adaptive provider checks `SystemLanguageModel.default.availability` at runtime, not merely framework linkage. Apple generation gets one fresh-session retry. If both attempts fail, the personalized local provider consumes the same semantic brief, while the UI exposes the fallback and the event log keeps the underlying error.

The shared brief recognizes attendance, celebration, recruiting, transfer, injury, ranking, helmet, streak, result, greeting, challenge, explanation, and controversy events. It always carries the canonical favorite, rival, and preferred tone. The signal extractor separately measures valence and arousal, including punctuation, anticipation language, and known traditions. For example, “I’m going to the Whiteout game!!!” becomes high-arousal positive attendance tied to Penn State, so the initial policy selects Foam Finger and Electric rather than Point Right.

The Foundation Models provider uses one compact `LanguageModelSession` at a time with stable commissioner instructions. On the verified iOS 26.4.1 simulator, Apple's default 300M safety-model asset crashes while decoding `thoughtContents`, before the available 3B language model can answer. The provider uses Apple's documented `permissiveContentTransformations` guardrail with string output to bypass that broken decoder. Structured `@Generable` output is intentionally not used on this path because Apple documents that non-string responses retain default guardrail behavior.

Swift converts the selected string into `CommishReaction` using the brief's deterministic action and emotion, no model-authored memory, control-label sanitization, topic/personalization scoring, and the normal 18-word validator. Opinion questions add a reasoning-and-rewrite pass. Other events request three alternatives so malformed, generic, or contradictory candidates can be rejected without another model invocation.

If Apple completes generation but none of its candidates satisfies the editorial contract, the same provider uses its deterministic local editor and transparently reports `Apple + local editor`. That quality repair is distinct from an Apple runtime failure: only runtime failures take the adaptive provider's retry-and-fallback path. The provider rejects concurrent generation, resets after six responses, and exposes a manual reset.

Read-only Foundation Models `Tool` types were intentionally omitted. The required fan facts are already local, and `ReactionBriefBuilder` gives both providers the same compact, validated perspective without another invocation surface.

## App-owned memory

SwiftData is canonical memory; the model transcript is not. `FanProfile` is the sole source for favorite team, rival team, and preferred tone. A launch migration removes legacy duplicate rows. The separate memory list is bounded to twelve recurring interests and supports case-insensitive deduplication, individual deletion, Forget Everything, and demo-data restore. The model may propose a candidate, but `MemoryPolicy` accepts it only when its value appears in the user's event and it is a supported durable, nonsensitive category.

Reaction learning is explicit rather than inferred from mere use. After each response, the fan can approve the reaction or correct it toward excited, supportive, curious, irritated, disappointed, or composed behavior. `ReactionFeedback` records the event features, chosen line/provider, predicted action/emotion, and correction. `LearnedReactionPreference` keeps bounded local weights for matching signal/action/emotion combinations. The next brief applies those weights before hard semantic constraints, so a correction changes similar future situations without retraining or a server. The Memory sheet shows rating and learned-signal counts. Forget Everything deletes this learning as well as profile memory; feedback history is capped at 200 records.

Seeded values are visibly labeled demo data: Penn State, Ohio State, playful tone, seven-day streak, three Oregon helmets, and one Ohio State helmet.

## Apple system integration

`ReactWithCommishIntent` is exposed through App Shortcuts. It accepts a short event, writes only a pending in-app event, and opens Living Commish. Siri, Spotlight, Shortcuts, and the Action button can surface an App Shortcut where the OS and device support those features. The app owns the actual context, generation, validation, memory, and animation pipeline.

## Source asset audit

All selected sources are under `/Users/michaeliams/Desktop/Commish Animations`; originals were never changed. Every selected image is 512×512, has real alpha transparency, and belongs to a gap-free numeric sequence.

| Action | Exact source | Frames | First → last | Duration at 24 fps | Playback |
|---|---|---:|---|---:|---|
| idle | `Commish Idle Loop/images` | 90 | `seq_0_0.png` → `seq_0_89.png` | 3.75 s | loop |
| pointRight | `Commish PT Right/images` | 90 | `seq_0_0.png` → `seq_0_89.png` | 3.75 s | one shot |
| sadShrug | `Commish Shrug Sad/images` | 90 | `seq_0_0.png` → `seq_0_89.png` | 3.75 s | one shot |
| wave | `Commish Wave Loop/images` | 60 | `seq_0_0.png` → `seq_0_59.png` | 2.50 s | one shot, configurable |
| foamFinger | `FF Wave New/images` | 90 | `seq_0_0.png` → `seq_0_89.png` | 3.75 s | one shot |

No selected sequence has a missing or duplicated numeric frame; all dimensions match within each sequence. Although the source animation JSON declares 30 fps, the prototype uses the requested starting assumption of 24 fps from one centralized configuration.

`FF Wave Loop` and `FF Wave New` both contain 90 valid transparent frames. Seventy-four frames are byte-identical. The newer export was selected because its changed entrance and exit frames lower the foam finger, producing a cleaner transition to and from idle. The older export begins and ends with the finger raised.

The 420 selected frames were copied to `Resources/Animations` and that folder reference is included in the application target. Demo, standalone, ZIP, JSON, and duplicate exports were not copied.
