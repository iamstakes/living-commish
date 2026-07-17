import { useCallback, useState } from "react";
import { useConversation } from "@elevenlabs/react";
import type { CommishController } from "../types/commish";
import {
  handleAgentMessage,
  handleModeChange,
} from "../integrations/conversationAnimationMap";

interface CommishVoiceProps {
  controller: CommishController;
  onVoiceEvent?: (message: string) => void;
}

interface ConversationMessage {
  message?: string;
  source?: "user" | "ai";
}

interface ModeChangeEvent {
  mode: "speaking" | "listening";
}

function readableStartError(error: unknown) {
  const message =
    error instanceof Error ? error.message : "Failed to start conversation.";

  if (/permission denied|notallowed/i.test(message)) {
    return "Microphone permission was denied. Allow microphone access for this local page, then click again.";
  }

  if (/unknown error/i.test(message)) {
    return "ElevenLabs returned a server error. Try again; if it repeats, check the agent settings or remove unsupported overrides.";
  }

  return message;
}

export function CommishVoice({ controller, onVoiceEvent }: CommishVoiceProps) {
  const [localStatus, setLocalStatus] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const conversation = useConversation({
    onConnect: () => {
      setLocalStatus(null);
      setErrorMessage(null);
      onVoiceEvent?.("Voice connected.");
      controller.play("wave");
    },
    onDisconnect: () => {
      setLocalStatus(null);
      onVoiceEvent?.("Voice disconnected.");
      controller.reset();
    },
    onModeChange: ({ mode }: ModeChangeEvent) =>
      handleModeChange(mode, controller),
    onMessage: (message: ConversationMessage) => {
      if (message.source === "ai") {
        const action = handleAgentMessage(message.message ?? "", controller);
        if (action) {
          onVoiceEvent?.(`Voice gesture: ${action}`);
        }
      }
    },
    onError: (error: unknown) => {
      const message = String(error || "Conversation error");
      setErrorMessage(message);
      setLocalStatus(null);
      console.error("[Commish] conversation error", error);
    },
  });

  const start = useCallback(async () => {
    setErrorMessage(null);
    setLocalStatus("Requesting microphone...");

    try {
      if (!navigator.mediaDevices?.getUserMedia) {
        throw new Error(
          "This browser did not expose microphone access for the local page.",
        );
      }

      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach((track) => track.stop());
      setLocalStatus("Connecting...");
      conversation.startSession();
    } catch (error) {
      setErrorMessage(readableStartError(error));
      setLocalStatus(null);
      console.error("[Commish] failed to start session", error);
    }
  }, [conversation]);

  const stop = useCallback(() => {
    setLocalStatus("Disconnecting...");
    conversation.endSession();
  }, [conversation]);

  const connected = conversation.status === "connected";
  const connecting = conversation.status === "connecting";

  return (
    <div className="commish-voice">
      <button
        type="button"
        onClick={connected ? stop : start}
        disabled={connecting || !controller.isReady}
      >
        {connected
          ? "End conversation"
          : connecting
            ? "Connecting..."
            : "Talk to the Commish"}
      </button>
      <span className="commish-voice__status">
        {localStatus ?? conversation.status}
        {connected
          ? conversation.isSpeaking
            ? " - speaking"
            : " - listening"
          : ""}
      </span>
      {errorMessage ? (
        <span className="commish-voice__error">{errorMessage}</span>
      ) : null}
    </div>
  );
}
