import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  Alignment,
  Fit,
  Layout,
  useRive,
  useStateMachineInput,
  useViewModelInstanceTrigger,
} from "@rive-app/react-webgl2";
import { commishAnimations } from "../config/commishAnimations";
import type { CommishAction, CommishController } from "../types/commish";

const stateMachineName = "CommishSM";

interface RiveCommishControllerProps {
  onActionChange(action: CommishAction): void;
  onController(controller: CommishController): void;
  onFail(reason: string): void;
  onLog(message: string): void;
}

type TriggerMap = Record<Exclude<CommishAction, "idle">, () => void>;

export function RiveCommishController({
  onActionChange,
  onController,
  onFail,
  onLog,
}: RiveCommishControllerProps) {
  const [isReady, setIsReady] = useState(false);
  const [currentAction, setCurrentAction] = useState<CommishAction>("idle");
  const actionRef = useRef<CommishAction>("idle");

  const layout = useMemo(
    () =>
      new Layout({
        fit: Fit.Contain,
        alignment: Alignment.Center,
      }),
    [],
  );

  const { rive, RiveComponent } = useRive({
    src: "/commish.riv",
    artboard: "Commish",
    stateMachines: stateMachineName,
    autoplay: true,
    autoBind: true,
    layout,
    onRiveReady: () => {
      setIsReady(true);
      onLog("Rive file loaded.");
    },
    onLoadError: () => {
      onFail("Rive file could not be loaded. Falling back to PNG frames.");
    },
  });

  const viewModelInstance = rive?.viewModelInstance ?? null;

  const pointRightVm = useViewModelInstanceTrigger(
    "pointRight",
    viewModelInstance,
  );
  const sadShrugVm = useViewModelInstanceTrigger("sadShrug", viewModelInstance);
  const waveVm = useViewModelInstanceTrigger("wave", viewModelInstance);
  const foamFingerVm = useViewModelInstanceTrigger(
    "foamFinger",
    viewModelInstance,
  );

  const pointRightInput = useStateMachineInput(
    rive,
    stateMachineName,
    "pointRight",
  );
  const sadShrugInput = useStateMachineInput(
    rive,
    stateMachineName,
    "sadShrug",
  );
  const waveInput = useStateMachineInput(rive, stateMachineName, "wave");
  const foamFingerInput = useStateMachineInput(
    rive,
    stateMachineName,
    "foamFinger",
  );

  const fireAction = useCallback(
    (action: CommishAction) => {
      actionRef.current = action;
      setCurrentAction(action);
      onActionChange(action);

      if (action === "idle") {
        rive?.reset({
          artboard: "Commish",
          stateMachines: stateMachineName,
          autoplay: true,
        });
        onLog("Rive: Idle");
        return;
      }

      const vmTriggers: TriggerMap = {
        pointRight: pointRightVm.trigger,
        sadShrug: sadShrugVm.trigger,
        wave: waveVm.trigger,
        foamFinger: foamFingerVm.trigger,
      };

      const legacyInputs = {
        pointRight: pointRightInput,
        sadShrug: sadShrugInput,
        wave: waveInput,
        foamFinger: foamFingerInput,
      };

      try {
        vmTriggers[action]();
      } catch {
        legacyInputs[action]?.fire?.();
      }

      if (legacyInputs[action]) {
        legacyInputs[action]?.fire?.();
      }

      onLog(`Rive: ${commishAnimations[action].label}`);
    },
    [
      foamFingerInput,
      foamFingerVm.trigger,
      onActionChange,
      onLog,
      pointRightInput,
      pointRightVm.trigger,
      rive,
      sadShrugInput,
      sadShrugVm.trigger,
      waveInput,
      waveVm.trigger,
    ],
  );

  const controller = useMemo<CommishController>(
    () => ({
      play(action: CommishAction) {
        if (!isReady) {
          onLog("Rive is still loading.");
          return;
        }
        fireAction(action);
      },
      reset() {
        fireAction("idle");
      },
      get isReady() {
        return isReady;
      },
      get currentAction() {
        return actionRef.current;
      },
    }),
    [fireAction, isReady, onLog],
  );

  useEffect(() => {
    onController(controller);
  }, [controller, onController]);

  useEffect(() => {
    if (isReady) {
      actionRef.current = "idle";
      setCurrentAction("idle");
      onActionChange("idle");
    }
  }, [isReady, onActionChange]);

  return (
    <div className="character-frame rive-frame">
      <RiveComponent
        aria-label={`Commish ${commishAnimations[currentAction].label}`}
      />
    </div>
  );
}

