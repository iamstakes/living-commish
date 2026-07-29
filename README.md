# Baseball Living Host

Baseball Living Host is a native iOS prototype in which an animated Commish
guides a personalized baseball experience. The character remains the primary
interface while onboarding, discovery cards, and search results appear on the
same stage.

The app now has one product path:

- Signed-out users meet the generic Commish and complete onboarding in cards.
- Fans choose from all 30 MLB teams and then select a player from that team.
- Completing onboarding opens the personalized discovery stage.
- Search interprets natural language with Apple Foundation Models when
  available and falls back to a deterministic local interpreter.
- Search results replace the discovery cards without navigating away from the
  Commish.
- Tapping the personalized Commish opens the fan profile and demo sign-out
  control.

Prototype baseball facts come from isolated local fixtures. They are not
presented as live MLB data.

## Requirements

- Xcode 26.4.1 or newer
- iOS 26.0 or newer
- An Apple Intelligence-capable device or simulator for the Foundation Models
  path

No backend, API key, remote model, or web runtime is required.

## Run

1. Open `LivingCommish.xcodeproj`.
2. Select the `LivingCommish` scheme and an iOS 26 simulator.
3. Press Run.

The checked-in PNG sequences are the production-safe character renderer. An
exported Rive asset can replace them when available; see `RIVE_SETUP.md` and
`Documentation/RIVE_IMPLEMENTATION.md`.

## Verify

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

- `Documentation/ARCHITECTURE.md` for current product and code boundaries
- `Documentation/APPLE_INTELLIGENCE_SETUP.md` for search interpretation
- `Documentation/DEMO_SCRIPT.md` for the review flow
