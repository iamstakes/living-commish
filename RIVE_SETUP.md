# Living Commish Rive Setup

This file is the manual Rive Editor work plan. These steps cannot be genuinely automated from this local app because they require your Rive account, the Rive Editor UI, and visual checking of imported timelines.

## 1. Create The File And Artboard

1. Open Rive and create a new file.
2. Rename the main artboard to `Commish`.
3. Set the artboard size to 512 by 512 pixels.
4. Keep the background transparent.

## 2. Import Each PNG Sequence

Use the copied source frames from the local app project, or the original Desktop folders if you prefer:

- Idle: `public/animations/idle/seq_0_0.png` through `seq_0_89.png`
- PointRight: `public/animations/point-right/seq_0_0.png` through `seq_0_89.png`
- SadShrug: `public/animations/sad-shrug/seq_0_0.png` through `seq_0_89.png`
- Wave: `public/animations/wave/seq_0_0.png` through `seq_0_59.png`
- FoamFinger: `public/animations/foam-finger/seq_0_0.png` through `seq_0_89.png`

For each sequence:

1. Import the PNG files as an image sequence.
2. Before confirming, make sure the frames are in numerical order: `seq_0_0.png`, `seq_0_1.png`, `seq_0_2.png`, and so on.
3. Watch for alphabetical sorting mistakes where `seq_0_10.png` appears before `seq_0_2.png`.
4. Place the sequence centered on the `Commish` artboard.

## 3. Create Timeline Animations

Create these animations with exactly these names:

- `Idle`
- `PointRight`
- `SadShrug`
- `Wave`
- `FoamFinger`

For each animation:

1. Add the corresponding imported image sequence to the timeline.
2. Use 30 fps to match the source JSON exports.
3. Confirm the character stays centered and uncropped.
4. Set `Idle` to loop.
5. Preview `Wave`. If it looks good as a repeated wave, you may keep the source timeline loopable, but the state machine should still return to idle after one complete performance for this prototype.
6. Keep `PointRight`, `SadShrug`, and `FoamFinger` as one-shot animations.

## 4. Create The State Machine

1. Create a state machine named `CommishSM`.
2. Set `CommishSM` as the default state machine for the `Commish` artboard.
3. Add states for:
   - `Idle`
   - `PointRight`
   - `SadShrug`
   - `Wave`
   - `FoamFinger`
4. Connect `Entry` to `Idle`.

## 5. Create Runtime Controls

Preferred current approach:

1. Create a View Model for the artboard if your Rive Editor version supports Data Binding.
2. Add Trigger properties named exactly:
   - `pointRight`
   - `sadShrug`
   - `wave`
   - `foamFinger`
3. Bind those trigger properties to the matching state machine transitions.
4. Make that View Model the default for the `Commish` artboard.

Fallback approach if Data Binding is not available or feels blocked:

1. Create classic state-machine Trigger inputs named exactly:
   - `pointRight`
   - `sadShrug`
   - `wave`
   - `foamFinger`
2. The app also attempts these legacy trigger inputs.

## 6. Create Transitions

Create these transitions:

- `Idle` to `PointRight` when `pointRight` fires.
- `Idle` to `SadShrug` when `sadShrug` fires.
- `Idle` to `Wave` when `wave` fires.
- `Idle` to `FoamFinger` when `foamFinger` fires.
- `PointRight` to `Idle` at 100% exit time.
- `SadShrug` to `Idle` at 100% exit time.
- `Wave` to `Idle` after one complete performance.
- `FoamFinger` to `Idle` at 100% exit time.

Use nearly instantaneous transitions first. If a transition pops visually, try a very short blend and preview again.

## 7. Preview And Export

1. In Rive Preview, start from `Idle`.
2. Fire every trigger one at a time.
3. Confirm each action returns to `Idle`.
4. Confirm the character is not cropped.
5. Export a runtime `.riv` file.
6. Save it into this project as:

```text
public/commish.riv
```

## 8. Test In The Local App

From the project folder:

```bash
npm run dev
```

Open the local URL Vite prints. The app should show `Renderer: Rive` if `public/commish.riv` loads successfully. If the Rive file is absent or invalid, it should show `Renderer: PNG fallback` and the demo will still work.

