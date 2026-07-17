import type { CommishAction } from "../types/commish";

export interface CommishAnimationDefinition {
  action: CommishAction;
  label: string;
  folder: string;
  frameCount: number;
  fps: number;
  loops: boolean;
  keyboard: string;
  expectedSize: {
    width: number;
    height: number;
  };
  sourcePath: string;
  onePerformanceMs?: number;
}

const sourceRoot = "/Users/michaeliams/Desktop/Commish Animations";

export const commishAnimations: Record<
  CommishAction,
  CommishAnimationDefinition
> = {
  idle: {
    action: "idle",
    label: "Idle",
    folder: "idle",
    frameCount: 90,
    fps: 30,
    loops: true,
    keyboard: "0",
    expectedSize: { width: 512, height: 512 },
    sourcePath: `${sourceRoot}/Commish Idle Loop/images`,
  },
  pointRight: {
    action: "pointRight",
    label: "Point Right",
    folder: "point-right",
    frameCount: 90,
    fps: 30,
    loops: false,
    keyboard: "1",
    expectedSize: { width: 512, height: 512 },
    sourcePath: `${sourceRoot}/Commish PT Right/images`,
  },
  sadShrug: {
    action: "sadShrug",
    label: "Sad Shrug",
    folder: "sad-shrug",
    frameCount: 90,
    fps: 30,
    loops: false,
    keyboard: "2",
    expectedSize: { width: 512, height: 512 },
    sourcePath: `${sourceRoot}/Commish Shrug Sad/images`,
  },
  wave: {
    action: "wave",
    label: "Wave",
    folder: "wave",
    frameCount: 60,
    fps: 30,
    loops: true,
    keyboard: "3",
    expectedSize: { width: 512, height: 512 },
    sourcePath: `${sourceRoot}/Commish Wave Loop/images`,
    onePerformanceMs: 2000,
  },
  foamFinger: {
    action: "foamFinger",
    label: "Foam Finger",
    folder: "foam-finger",
    frameCount: 90,
    fps: 30,
    loops: false,
    keyboard: "4",
    expectedSize: { width: 512, height: 512 },
    sourcePath: `${sourceRoot}/FF Wave New/images`,
  },
};

export const actionOrder: CommishAction[] = [
  "idle",
  "pointRight",
  "sadShrug",
  "wave",
  "foamFinger",
];

export const demoSequence: CommishAction[] = [
  "idle",
  "wave",
  "pointRight",
  "foamFinger",
  "sadShrug",
  "idle",
];

export function frameUrlsFor(action: CommishAction): string[] {
  const definition = commishAnimations[action];

  return Array.from({ length: definition.frameCount }, (_, index) => {
    return `/animations/${definition.folder}/seq_0_${index}.png`;
  });
}

export function durationFor(action: CommishAction): number {
  const definition = commishAnimations[action];
  return (
    definition.onePerformanceMs ??
    Math.ceil((definition.frameCount / definition.fps) * 1000)
  );
}

