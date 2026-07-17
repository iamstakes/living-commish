import type { CommishAction, CommishController } from "../types/commish";
import { pickGestureFromText } from "./commishGestures";

export type MockConversationEvent =
  | { type: "agent.listening" }
  | { type: "agent.thinking" }
  | { type: "agent.speaking" }
  | { type: "result.positive" }
  | { type: "result.negative" }
  | { type: "conversation.ended" };

export const conversationAnimationMap: Record<
  MockConversationEvent["type"],
  CommishAction
> = {
  "agent.listening": "idle",
  "agent.thinking": "pointRight",
  "agent.speaking": "wave",
  "result.positive": "foamFinger",
  "result.negative": "sadShrug",
  "conversation.ended": "idle",
};

export function handleConversationEvent(
  event: MockConversationEvent,
  controller: Pick<CommishController, "play">,
) {
  const action = conversationAnimationMap[event.type];
  controller.play(action);
  return action;
}

export type ConversationMode = "speaking" | "listening";

export function handleAgentMessage(
  text: string,
  controller: Pick<CommishController, "play">,
): CommishAction | null {
  const action = pickGestureFromText(text);
  if (action) {
    controller.play(action);
  }
  return action;
}

export function handleModeChange(
  mode: ConversationMode,
  controller: Pick<CommishController, "play" | "reset">,
): void {
  if (mode === "listening") {
    controller.reset();
  }
}

