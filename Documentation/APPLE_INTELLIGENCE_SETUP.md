# Apple Intelligence search interpretation

## Role in the product

Apple Foundation Models converts a natural-language baseball query into a
small search specification:

- intent
- player and team entities
- time scope
- whether the request needs the fan's personal history

It does not generate standings, statistics, scores, roster facts, schedules,
or the final result cards. Those must come from `BaseballDataProviding`.

For example, `mike schmidt` becomes a player entity lookup. `What is my
favorite team?` becomes a favorite-team lookup grounded in the profile
snapshot.

## Runtime behavior

`AdaptiveBaseballQueryInterpreter` checks
`SystemLanguageModel.default.isAvailable` at request time.

1. When available, it creates a short-lived `LanguageModelSession`, asks for
   one JSON classification, decodes it, and normalizes known entity aliases.
2. If Apple returns an unknown intent, invalid JSON, or a runtime error, the
   deterministic interpreter handles the same text.
3. Cancellation propagates immediately and never starts fallback work.
4. UI-test launch arguments force deterministic interpretation so tests remain
   repeatable.

The Apple prompt explicitly forbids answering the question or inventing a
baseball fact. The app also canonicalizes supported names such as Aaron Judge,
Shohei Ohtani, Hunter Goodman, Mike Schmidt, the Rockies, and the Dodgers
before planning.

## Requirements

- Xcode 26.4.1 or newer
- iOS 26.0 or newer
- An Apple Intelligence-capable device or simulator
- Apple Intelligence enabled and its on-device model ready

No model download, API key, or server configuration is owned by this app.
System Settings controls Apple Intelligence availability.

Official references:

- [Foundation Models framework](https://developer.apple.com/documentation/foundationmodels)
- [SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)
- [LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)

## Verification

Run the app without UI-test launch arguments and search for:

1. `mike schmidt`
2. `What is my favorite team?`
3. `Compare Judge and Ohtani`

In a Debug build, successful Apple interpretation prints
`Baseball search interpreted by Apple Foundation Models.` If the model is
unavailable or a request fails, the query should still resolve through the
deterministic interpreter when it is in the supported prototype corpus.

The result must remain on the Commish stage in either case. The user should
never see a different fallback product or an interstitial asking them to
abandon a valid baseball query.
