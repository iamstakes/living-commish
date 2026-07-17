export type CommishAction =
  | "idle"
  | "pointRight"
  | "sadShrug"
  | "wave"
  | "foamFinger";

export interface CommishController {
  play(action: CommishAction): void;
  reset(): void;
  isReady: boolean;
  currentAction: CommishAction;
}

export type RendererMode = "Rive" | "PNG fallback";

