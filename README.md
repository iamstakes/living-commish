# College Football Commish
College Football Commish is a native iOS prototype in which an animated host guides a personalized college-football experience. It is an isolated clone of the Living Commish interaction system with its own Xcode project, target, bundle identifier, domain models, and demo fixtures.

## Demo experience

- Choose from 30 featured FBS programs and a current or legendary player.
- Land on a personalized Saturday feed led by rivalry, conference, player, quiz, and watch-next cards.
- Search for players and programs with deterministic fixture-backed results.
- Explore Travis Hunter’s four-image two-way archive and complete his quiz for a legendary card.
- Complete the Buffs history Daily Drop for a rare Rashaan Salaam card.
- Reset onboarding, collected cards, and avatar state for repeatable demos.

Colorado is the primary demo profile. Historical facts in the Hunter and Buffaloes flows are grounded in University of Colorado Athletics and Heisman Trophy Trust material. Schedule and playoff cards are clearly labeled prototype fixtures until a live provider is connected.

## Build and test

```sh
xcodebuild build \
  -project CollegeFootballCommish.xcodeproj \
  -scheme CollegeFootballCommish \
  -destination 'platform=iOS Simulator,name=iPhone 17'

xcodebuild test \
  -project CollegeFootballCommish.xcodeproj \
  -scheme CollegeFootballCommish \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

The default scheme runs the fast unit suite. Use `CollegeFootballCommishE2E` for the focused UI smoke tests.
