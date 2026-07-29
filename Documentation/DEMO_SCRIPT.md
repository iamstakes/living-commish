# 60–90 second demo

## Setup

Reset onboarding and launch on the iPhone 17 Pro simulator. The opening screen
should contain the generic Commish and the first onboarding card—never an empty
stage.

## Script

**0–20 seconds — Commish-led onboarding**

“The Commish is the interface from the first launch. I can choose any of the 30
MLB teams without leaving the stage.”

Open the team card, select the Colorado Rockies, then choose Hunter Goodman
from the player card.

**20–35 seconds — Personalized stage**

Complete onboarding.

“My choices change the stage to Rockies purple and personalize what the
Commish presents. Tapping the character opens my profile.”

Show the final-score card, standings card, and story preview. Point out that
the cards stay low and tappable while the character remains visible.

**35–55 seconds — Natural-language search**

Search for `mike schmidt`.

“Apple Intelligence interprets the query when available, but it is not allowed
to invent baseball facts. A data provider grounds the result, and the result
replaces these cards on the same stage.”

Dismiss the keyboard by tapping the stage, then clear the result to return to
discovery.

**55–70 seconds — Personal context**

Search for `What is my favorite team?`

“The query explicitly asks for personal context, so the answer comes from the
team I selected during onboarding.”

**70–85 seconds — Resilience**

“The current baseball provider uses transparent prototype fixtures. Search has
a deterministic local interpreter if Apple Intelligence is unavailable, and
the character has a tested PNG renderer if the Rive asset is unavailable. The
same interface survives both fallbacks.”

## Reset

Tap the Commish, choose the onboarding reset control, and confirm the app
returns to the signed-out team-selection card.
