import type { CommishAction } from "../types/commish";

export const LIVING_COMMISH_AGENT_ID = "agent_3501kxpwarm0fn5vwenqs4k891b5";

const RULES: { action: CommishAction; test: RegExp }[] = [
  {
    action: "foamFinger",
    test: /\b(foam finger|foamfinger|let'?s go+|touchdown|go+a+l|huge|unbelievable|what a|clutch|we won|nailed it|boom|amazing|incredible|hype|dub|so good)\b/i,
  },
  {
    action: "sadShrug",
    test: /\b(sad shrug|sadshrug|shrug sad|unlucky|tough break|tough|brutal|robbed|bad call|terrible call|come on ref|blown|choked|disaster|we lost|painful|heartbreak|oh no|yikes|rough)\b/i,
  },
  {
    action: "pointRight",
    test: /\b(point right|pointright|pointing right|look at|watch this|right there|check that|i'?m telling you|listen|called it|that guy|over there|mark my words|see that)\b/i,
  },
  {
    action: "wave",
    test: /\b(wave|waving|hey|hello|hi there|welcome|what'?s up|how'?s it going|good to see|see you|later|bye|catch you)\b/i,
  },
];

export function pickGestureFromText(text: string): CommishAction | null {
  if (!text) {
    return null;
  }

  for (const { action, test } of RULES) {
    if (test.test(text)) {
      return action;
    }
  }

  return null;
}
