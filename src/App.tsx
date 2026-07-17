import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import "./App.css";
import {
  actionOrder,
  commishAnimations,
  demoSequence,
  durationFor,
} from "./config/commishAnimations";
import { CommishVoice } from "./components/CommishVoice";
import { PngSequenceCommishController } from "./controllers/PngSequenceCommishController";
import { RiveCommishController } from "./controllers/RiveCommishController";
import type {
  CommishAction,
  CommishController,
  RendererMode,
} from "./types/commish";

function createNoopController(): CommishController {
  return {
    play() {},
    reset() {},
    isReady: false,
    currentAction: "idle",
  };
}

function App() {
  const [controller, setController] = useState<CommishController>(
    createNoopController,
  );
  const [currentAction, setCurrentAction] = useState<CommishAction>("idle");
  const [renderer, setRenderer] = useState<RendererMode>("PNG fallback");
  const [shouldTryRive, setShouldTryRive] = useState(false);
  const [log, setLog] = useState<string[]>(["App started."]);
  const [isDemoRunning, setIsDemoRunning] = useState(false);
  const demoAbortRef = useRef(false);

  const addLog = useCallback((message: string) => {
    const time = new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
    setLog((items) => [`${time} ${message}`, ...items].slice(0, 7));
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function detectRiveFile() {
      try {
        const response = await fetch("/commish.riv", {
          cache: "no-store",
        });
        const contentType = response.headers.get("content-type") ?? "";
        const bytes = await response.arrayBuffer();
        const startsWithHtml =
          new TextDecoder()
            .decode(bytes.slice(0, Math.min(bytes.byteLength, 32)))
            .trim()
            .startsWith("<");
        const looksLikeRive =
          response.ok &&
          bytes.byteLength > 0 &&
          !contentType.includes("text/html") &&
          !startsWithHtml;

        if (!cancelled && looksLikeRive) {
          setShouldTryRive(true);
          setRenderer("Rive");
          addLog("Found public/commish.riv. Trying Rive renderer.");
        } else if (!cancelled) {
          addLog("No public/commish.riv found. Using PNG fallback.");
        }
      } catch {
        if (!cancelled) {
          addLog("Could not check public/commish.riv. Using PNG fallback.");
        }
      }
    }

    detectRiveFile();

    return () => {
      cancelled = true;
    };
  }, [addLog]);

  const playAction = useCallback(
    (action: CommishAction) => {
      demoAbortRef.current = true;
      setIsDemoRunning(false);
      controller.play(action);
    },
    [controller],
  );

  const runDemoSequence = useCallback(async () => {
    demoAbortRef.current = false;
    setIsDemoRunning(true);
    addLog("Demo sequence started.");

    for (const action of demoSequence) {
      if (demoAbortRef.current) {
        break;
      }

      controller.play(action);
      await new Promise((resolve) =>
        window.setTimeout(
          resolve,
          action === "idle" ? 700 : durationFor(action),
        ),
      );
    }

    if (!demoAbortRef.current) {
      controller.play("idle");
      addLog("Demo sequence complete.");
    }

    setIsDemoRunning(false);
  }, [addLog, controller]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (
        event.target instanceof HTMLInputElement ||
        event.target instanceof HTMLTextAreaElement ||
        event.target instanceof HTMLSelectElement
      ) {
        return;
      }

      const match = actionOrder.find(
        (action) => commishAnimations[action].keyboard === event.key,
      );

      if (match) {
        event.preventDefault();
        playAction(match);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [playAction]);

  const statusText = useMemo(() => {
    return controller.isReady ? "Ready" : "Loading";
  }, [controller.isReady]);

  const handleRiveFail = useCallback(
    (reason: string) => {
      setShouldTryRive(false);
      setRenderer("PNG fallback");
      addLog(reason);
    },
    [addLog],
  );

  return (
    <main className="app-shell">
      <section className="stage" aria-label="Living Commish animation stage">
        <div className="stage-header">
          <div>
            <p className="eyebrow">Living Commish</p>
            <h1>{commishAnimations[currentAction].label}</h1>
          </div>
          <div className="status-stack" aria-label="Character status">
            <span>Renderer: {renderer}</span>
            <span>State: {commishAnimations[currentAction].label}</span>
            <span>{statusText}</span>
          </div>
        </div>

        <div className="character-stage">
          {shouldTryRive ? (
            <RiveCommishController
              onActionChange={setCurrentAction}
              onController={setController}
              onFail={handleRiveFail}
              onLog={addLog}
            />
          ) : (
            <PngSequenceCommishController
              onActionChange={setCurrentAction}
              onController={setController}
              onLog={addLog}
            />
          )}
        </div>

        <div className="controls" aria-label="Animation controls">
          {actionOrder.map((action) => (
            <button
              type="button"
              key={action}
              className={currentAction === action ? "active" : ""}
              onClick={() => playAction(action)}
            >
              <span>{commishAnimations[action].keyboard}</span>
              {commishAnimations[action].label}
            </button>
          ))}
          <button
            type="button"
            className="demo-button"
            onClick={runDemoSequence}
            disabled={isDemoRunning}
          >
            Demo Sequence
          </button>
        </div>

        <CommishVoice controller={controller} onVoiceEvent={addLog} />
      </section>

      <aside className="event-log" aria-label="Recent animation event log">
        <h2>Event Log</h2>
        <ol>
          {log.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ol>
      </aside>
    </main>
  );
}

export default App;
