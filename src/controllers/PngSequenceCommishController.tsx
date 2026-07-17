import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  commishAnimations,
  durationFor,
  frameUrlsFor,
} from "../config/commishAnimations";
import type { CommishAction, CommishController } from "../types/commish";

type FrameMap = Record<CommishAction, string[]>;

interface PngSequenceCommishControllerProps {
  onActionChange(action: CommishAction): void;
  onLog(message: string): void;
  onController(controller: CommishController): void;
}

interface LoadState {
  isReady: boolean;
  error: string | null;
}

function createEmptyFrameMap(): FrameMap {
  return {
    idle: [],
    pointRight: [],
    sadShrug: [],
    wave: [],
    foamFinger: [],
  };
}

function preloadImage(src: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(src);
    image.onerror = () =>
      reject(new Error(`Missing or unreadable animation frame: ${src}`));
    image.src = src;
  });
}

export function PngSequenceCommishController({
  onActionChange,
  onLog,
  onController,
}: PngSequenceCommishControllerProps) {
  const [loadState, setLoadState] = useState<LoadState>({
    isReady: false,
    error: null,
  });
  const [currentAction, setCurrentAction] = useState<CommishAction>("idle");
  const [frameIndex, setFrameIndex] = useState(0);
  const framesRef = useRef<FrameMap>(createEmptyFrameMap());
  const actionRef = useRef<CommishAction>("idle");
  const frameIndexRef = useRef(0);
  const actionStartedAtRef = useRef<number | null>(null);
  const lastFrameAtRef = useRef<number | null>(null);
  const rafRef = useRef<number | null>(null);

  const setAction = useCallback(
    (action: CommishAction) => {
      actionRef.current = action;
      frameIndexRef.current = 0;
      actionStartedAtRef.current = performance.now();
      lastFrameAtRef.current = null;
      setFrameIndex(0);
      setCurrentAction(action);
      onActionChange(action);
      onLog(`PNG: ${commishAnimations[action].label}`);
    },
    [onActionChange, onLog],
  );

  const controller = useMemo<CommishController>(
    () => ({
      play(action: CommishAction) {
        if (!loadState.isReady) {
          onLog("PNG frames are still preloading.");
          return;
        }
        setAction(action);
      },
      reset() {
        setAction("idle");
      },
      get isReady() {
        return loadState.isReady;
      },
      get currentAction() {
        return actionRef.current;
      },
    }),
    [loadState.isReady, onLog, setAction],
  );

  useEffect(() => {
    onController(controller);
  }, [controller, onController]);

  useEffect(() => {
    let cancelled = false;

    async function preloadAllFrames() {
      try {
        const loadedFrames = createEmptyFrameMap();

        for (const action of Object.keys(commishAnimations) as CommishAction[]) {
          const urls = frameUrlsFor(action);
          if (urls.length === 0) {
            throw new Error(
              `Animation folder has no configured frames: ${commishAnimations[action].folder}`,
            );
          }

          loadedFrames[action] = await Promise.all(urls.map(preloadImage));
        }

        if (!cancelled) {
          framesRef.current = loadedFrames;
          setLoadState({ isReady: true, error: null });
          setAction("idle");
          onLog("PNG frames preloaded.");
        }
      } catch (error) {
        if (!cancelled) {
          const message =
            error instanceof Error
              ? error.message
              : "Unknown PNG preload error.";
          setLoadState({ isReady: false, error: message });
          onLog(message);
        }
      }
    }

    preloadAllFrames();

    return () => {
      cancelled = true;
    };
  }, [onLog, setAction]);

  useEffect(() => {
    if (!loadState.isReady) {
      return;
    }

    const tick = (now: number) => {
      const action = actionRef.current;
      const definition = commishAnimations[action];
      const frames = framesRef.current[action];
      const frameDuration = 1000 / definition.fps;
      if (lastFrameAtRef.current === null) {
        lastFrameAtRef.current = now;
      }
      const lastFrameAt = lastFrameAtRef.current;
      const elapsed = now - lastFrameAt;

      if (elapsed >= frameDuration && frames.length > 0) {
        const steps = Math.max(1, Math.floor(elapsed / frameDuration));
        const nextIndex = frameIndexRef.current + steps;

        if (definition.loops) {
          frameIndexRef.current = nextIndex % frames.length;
        } else if (nextIndex >= frames.length) {
          setAction("idle");
        } else {
          frameIndexRef.current = nextIndex;
        }

        lastFrameAtRef.current = now;
        setFrameIndex(frameIndexRef.current);
      }

      const startedAt = actionStartedAtRef.current;
      if (
        action !== "idle" &&
        definition.loops &&
        definition.onePerformanceMs &&
        startedAt &&
        now - startedAt >= definition.onePerformanceMs
      ) {
        setAction("idle");
      }

      if (
        action !== "idle" &&
        !definition.loops &&
        startedAt &&
        now - startedAt >= durationFor(action)
      ) {
        setAction("idle");
      }

      rafRef.current = requestAnimationFrame(tick);
    };

    rafRef.current = requestAnimationFrame(tick);

    return () => {
      if (rafRef.current) {
        cancelAnimationFrame(rafRef.current);
      }
    };
  }, [loadState.isReady, setAction]);

  const currentFrames = framesRef.current[currentAction];
  const currentFrameSrc = currentFrames[frameIndex] ?? currentFrames[0];

  return (
    <div className="character-frame" aria-live="polite">
      {!loadState.isReady && !loadState.error ? (
        <div className="stage-message">Preloading Commish frames...</div>
      ) : null}
      {loadState.error ? (
        <div className="stage-error">{loadState.error}</div>
      ) : null}
      {currentFrameSrc ? (
        <img
          className="commish-image"
          src={currentFrameSrc}
          width={512}
          height={512}
          alt={`Commish ${commishAnimations[currentAction].label}`}
          draggable={false}
        />
      ) : null}
    </div>
  );
}
