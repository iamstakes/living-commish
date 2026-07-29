# Living Commish

Living Commish is a hackathon prototype for a personalized sports commissioner character. The repository contains the native iOS implementation and the earlier React/Vite prototype.

## Baseball Living Host branch

On `feature/baseball-search`, the native app launches into Baseball Living Host: a search-first, visual baseball experience with an animated guide. Apple Foundation Models interprets natural-language searches into an intent and named entities when the on-device model is available; the app then grounds those entities through its baseball data provider instead of treating generated text as baseball truth. A deterministic interpreter takes over when Apple Intelligence is unavailable or generation fails. The current data provider uses isolated prototype fixtures for Michael, a Colorado Rockies fan; it does not claim that the displayed MLB data is live.

Run the app normally for the baseball experience. To inspect the original Living Commish experience, add `--legacy-commish` to the scheme's launch arguments. The implementation plan and phase status live in `BASEBALL_BRANCH_PLAN.md`.

## Native iOS prototype

The SwiftUI app uses Apple Foundation Models for on-device copy generation when available. Inspectable Swift code owns event interpretation, action and emotion selection, validation, memory, and animation. A personalized deterministic provider keeps the demo functional when the Apple model is unavailable or fails.

The latest reaction policy recognizes intent, valence, arousal, punctuation, anticipation, team relationships, and known traditions. Explicit approval or correction is stored locally in SwiftData and adjusts bounded weights for similar future situations. For example, excited Whiteout attendance starts with `foamFinger` and `electric` instead of the old catch-all `pointRight` behavior.

### Requirements

- Xcode 26.4.1 or newer
- iOS 26.0 or newer
- An Apple Intelligence-capable simulator or device for the Foundation Models path

No backend, API key, or remote model is required.

### Run

1. Open `LivingCommish.xcodeproj`.
2. Select the `LivingCommish` scheme and an iOS 26 simulator.
3. Press Run.

The checked-in PNG sequences are the production-safe renderer fallback. Rive is optional; see `RIVE_SETUP.md` and `Documentation/RIVE_IMPLEMENTATION.md`.

### Verify

```sh
xcodebuild \
  -project LivingCommish.xcodeproj \
  -scheme LivingCommish \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

xcodebuild \
  -project LivingCommish.xcodeproj \
  -scheme LivingCommish \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

Start with:

- `Documentation/ARCHITECTURE.md` for the reaction, intelligence, renderer, and learning boundaries
- `Documentation/APPLE_INTELLIGENCE_SETUP.md` for runtime behavior and the simulator workaround
- `Documentation/DEMO_SCRIPT.md` for the review flow

## Web prototype

```sh
npm install
npm run dev
```

Other useful commands are `npm run build` and `npm run lint`.
