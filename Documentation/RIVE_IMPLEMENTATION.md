# Rive implementation

## Native runtime

The app uses the official `rive-ios` Swift package, pinned exactly to **6.21.1**, product `RiveRuntime`.

The adapter uses Rive's current Swift-first Apple API:

1. create an async `Worker`
2. load local `commish.riv` with `RiveRuntime.File`
3. instantiate artboard `Commish`
4. instantiate state machine `CommishSM`
5. inspect the default view model schema
6. require four trigger properties
7. bind that view model instance to the state machine
8. render with `RiveUIViewRepresentable` using contain/center fit

Current Rive guidance favors Data Binding for indirect state-machine control. The runtime contract therefore uses trigger properties named:

- `pointRight`
- `sadShrug`
- `wave`
- `foamFinger`

Idle is the default state and has no repeatedly fired input.

`RiveCommishController` owns all Rive types. `AdaptiveCommishController` selects it only after file parsing and complete schema validation. Missing file, parse error, artboard mismatch, state-machine mismatch, view-model mismatch, or missing trigger leaves the tested PNG renderer active and keeps a diagnostic reason for development inspection.

## Asset specification

The Rive project must contain one 512×512 artboard named `Commish` and these animations at 24 fps:

| Animation | Source folder | Frames | Loop |
|---|---|---:|---|
| `Idle` | `Commish Idle Loop/images` | 90 | yes |
| `PointRight` | `Commish PT Right/images` | 90 | no |
| `SadShrug` | `Commish Shrug Sad/images` | 90 | no |
| `Wave` | `Commish Wave Loop/images` | 60 | no in app behavior |
| `FoamFinger` | `FF Wave New/images` | 90 | no |

All image layers must share the same 512×512 bounds, center, scale, and origin. Alpha must remain transparent and the fit must never crop.

The required state graph is:

```text
Entry → Idle

Idle → PointRight  when pointRight fires
Idle → SadShrug    when sadShrug fires
Idle → Wave        when wave fires
Idle → FoamFinger  when foamFinger fires

PointRight → Idle  on completion
SadShrug → Idle    on completion
Wave → Idle        on completion
FoamFinger → Idle  on completion
```

Transitions should be effectively instantaneous unless visual inspection supports a short blend. Each one-shot completion exit must be tested in the editor before export.

## Editor/export status

The authenticated Rive project is **Living Commish** (project ID `1916610`). Its current editor file is file ID `2454580`. Browser automation created the 512×512 `Commish` component and imported all 420 approved frames with stable, action-prefixed names:

- `01_idle_000` … `01_idle_089`
- `02_point-right_000` … `02_point-right_089`
- `03_sad-shrug_000` … `03_sad-shrug_089`
- `04_wave_000` … `04_wave_059`
- `05_foam-finger_000` … `05_foam-finger_089`

The exact endpoints were checked in the Assets panel after upload. Rive currently has no direct PNG-sequence import, and the account rejected five generated Lottie image-sequence bridges without creating assets. The planned editor construction therefore uses a Rive Node script to render the named PNG frames at 24 fps and listen to the same four Data Binding triggers. The checked-in source of that editor script is `Rive/CommishPlayback.lua`; keeping it in the repository makes the intended Rive behavior reviewable and recoverable.

Rive scripting is supported by the Apple runtime used by this project. The script deliberately accesses the bound View Model through `Context` instead of the generated global `Data` table, avoiding the `Data`-global regression reported in recent 6.20.6–6.21.0 Apple runtime builds.

The Rive web editor's canvas code field did not accept automated or in-app-browser clipboard input, so the generated script remains checked in locally rather than falsely claiming it was installed in the Rive file.

The authenticated account is on Rive's **Free** plan. As of July 22, 2026, Rive's official pricing documentation includes State Machines, Data Binding, and Scripting on Free, but reserves runtime `.riv` export for Cadet and higher. No paid upgrade was authorized or attempted. This is now the hard boundary for the Rive path.

Editor script installation, the named placeholder timelines, `CommishSM`, export, and native visual validation therefore remain pending. No `commish.riv` is claimed to exist, so the app correctly uses its PNG fallback. The compiled native adapter is ready for a future exported asset and cannot accidentally accept an incomplete file.

The intended export location is:

```text
/Users/michaeliams/Desktop/LivingCommish/Resources/commish.riv
```

## Validation checklist after export

- Confirm `commish.riv` is in Copy Bundle Resources.
- Inspect the host controller and confirm it reports Rive only after async validation.
- Visually inspect idle for a complete loop and stable 512×512 alignment.
- Exercise onboarding, discovery, and search and confirm each requested behavior animates, remains uncropped, and returns to idle.
- Replace or corrupt a development copy and confirm PNG playback plus a useful diagnostic reason.
- Run the UI suite and a Release simulator build.

## Manual recovery

Manual recovery is not the primary workflow, but if the Rive asset later needs editing:

1. Open only the Living Commish Rive project.
2. Preserve the exact artboard, state machine, animation, and trigger names above.
3. Keep every raster frame at the same artboard origin and 24 fps timing.
4. If the scripted renderer is used, paste `Rive/CommishPlayback.lua` into the `CommishPlayback` Node script and attach it at the `Commish` origin.
5. Export a new runtime `.riv` file.
6. Replace only `Resources/commish.riv` in the app project.
7. Repeat the validation checklist; do not bypass the adaptive fallback.
