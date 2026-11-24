# Memory and CPU baseline (roadmap 0.4)

Every later phase is measured against this table: the Phase 1 exit criterion is "T0 peak memory at or below the baseline". The static part below comes from the compiler. The runtime part (peak memory in the simulator) was measured by hand by the project owner, because the simulator's memory view is a GUI feature.

Baseline version: `master` at `c7cc066` (latest release tag 2.3.5), SDK 9.3.0, built with the same options as the CI validation build (`monkeyc -w`, default optimization level, no `-r`).

## Static part: .prg size per tier device

Built locally with `tools/ci/tier-devices.txt`; the CI job summary of every `/validate` run prints the same table. The `.prg` size is a trend number, not the runtime budget: it is the size of the whole package file and is far above the data field memory limit, so it says nothing about whether the field fits.

| Tier | Device | Data field memory limit | .prg size (bytes) |
|---|---|---:|---:|
| T0 | fenix3 | 16 KB | 103340 |
| T1 | fenix5 | 32 KB | 104156 |
| T1 | fenix6 | 32 KB | 104156 |
| T1b | instincte40mm | 32 KB | 102524 |
| T2 | fenix847mm | 128 KB | 112092 |
| T2 | fenix9pro47mm | 128 KB | 112092 |
| T3 | fr965 | 256 KB | 112092 |

Memory limits come from `compiler.json` of each device (`appTypes`, type `datafield`).

## Runtime part: peak memory in the simulator

Measure for the same seven devices, once with the field alone on the data screen ("single") and once as one of four fields ("4-field"). Use the same settings every time: show previous lap on, default decimals, label visible, correction factors 100 %.

Steps (the menu names can differ per SDK version; use the memory view of the simulator, the one that shows used, free and peak bytes of the running app):

1. Start the simulator and load the field for the device (VS Code: run the build task for the device, or `monkeydo <prg> <device>`).
2. Open the data field screen layout (single field, then four fields) and start a simulated activity so `onUpdate` runs.
3. Add a lap or two (Simulation, timer lap) so the previous-lap string exists.
4. Let it run for at least 60 seconds, then read the peak (high-water) memory from the memory view. Record the peak, not the current value.
5. Repeat for each device and layout. Restart the simulator (or reload the app) before every single measurement, also when only the layout changes: the peak is a high-water mark, so a second layout measured in the same session would still show the larger peak of the first.

Measured values (peak memory in KB as the simulator's memory view shows it, one decimal; the limit is in the table above). Measured by the project owner in the simulator, on `master`. The code is the 2.3.5 release plus one line (the settings fallback fix `0d9d9c0`: `App.getApp().getProperty`); nothing else in `source/` changed.

| Tier | Device | Limit | Single field | 4-field | Notes |
|---|---|---:|---:|---:|---|
| T0 | fenix3 | 16 KB | 9.8 | 9.8 | |
| T1 | fenix5 | 32 KB | 12.7 | 12.7 | |
| T1 | fenix6 | 32 KB | 12.9 | 12.9 | |
| T1b | instincte40mm | 32 KB | 11.1 | 11.1 | The layout differs from the other devices (see roadmap Phase 7). |
| T2 | fenix847mm | 128 KB | 11.7 | 11.7 | |
| T2 | fenix9pro47mm | 128 KB | 11.9 | 11.9 | |
| T3 | fr965 | 256 KB | 11.6 | 11.6 | In the 4-field layout the simulator draws three of the four fields with overlapping digits and bold-looking labels; the single field is drawn correctly (see roadmap Phase 7). |

Findings:

- The peak does not depend on the layout: single field and 4-field give the same value on every device. The 4-field column therefore repeats the single-field value; it was not measured separately to a different result.
- The peak is lowest on fenix3 (9.8 KB) and between 11.1 and 12.9 KB on the other six devices, far below the limits of the larger tiers. The tight tier is T0: 9.8 KB of 16 KB, which leaves 6.2 KB of headroom for Phases 1 to 4.
- The update time is in the next section. It is a first reading, not yet a complete baseline.

## Update time (simulator profiler)

Measured by the project owner with the simulator profiler (File, View Profiler; Start, about 30 seconds, Stop), 30 calls of `compute` per capture. The profiler runs on the PC, so the times are simulator times, not watch times: use them to compare before and after a change, not as absolute numbers.

**fenix3 (T0), single-field layout** (inferred from the code: this capture has no `getValueFont`, which `onUpdate` calls only when `isSingleFieldLayout()` is false):

| Function | Total (us) | Average (us) | Calls | Share of `onUpdate` |
|---|---:|---:|---:|---:|
| `onUpdate` (includes the rows below) | 60915 | 2030.5 | 30 | 100 % |
| `WatchUi.loadResource` (the label strings) | 39349 | 655.8 | 60 | 65 % |
| `Dc.drawText` | 9800 | 108.9 | 90 | 16 % |
| `AppBase.getProperty` (settings, 6 per update) | 3505 | 19.5 | 180 | 6 % |
| `System.getDeviceSettings` | 512 | 17.1 | 30 | 1 % |

**fr965 (T3), multi-field (4-field) layout** (inferred from the code: the capture contains `getValueFont`, the font-fit loop that runs only in the multi-field branch). The capture has no `onUpdate` row, so there is no total per update. Its 240 `getValueFont` calls for 30 `compute` calls (8 per update, where the code calls it once per update) are not explained and need a check against the raw capture:

| Function | Total (us) | Average (us) | Calls |
|---|---:|---:|---:|
| `getValueFont` (inclusive) | 399062 | 1662.8 | 240 |
| `Dc.drawText` | 342604 | 3806.7 | 90 |
| `WatchUi.loadResource` | 36617 | 610.3 | 60 |
| `Properties.getValue` (settings) | 4536 | 25.2 | 180 |

What it shows:

- On T0, nearly two thirds of the update time is `loadResource`: the two label strings are loaded again on every update (about 1.3 ms of 2.0 ms). The same cost, about 1.2 ms per update, shows on the fr965. Loading them once (Phase 1.2 layout cache) is the largest single saving.
- Reading the settings on every update (6 calls) costs about 6 % on T0. Loading them once (Phase 1.1 `Settings`) removes it.
- On the fr965 in the multi-field layout the font-fit loop (`getValueFont`) and `drawText` dominate (3 `drawText` calls of about 3.8 ms each). Choosing the font only when the size or the text length changes (Phase 1.2) targets exactly that. The font-fit loop only exists in the multi-field path, so the single-field T0 numbers above do not include it.

Gaps, to close before Phase 1.2 starts: the two captures are different layouts and cannot be compared with each other. The gate device is T0, so capture fenix3 again in the 4-field layout (the path with the font-fit loop, probably its most expensive one) and note the layout with every capture. The fr965 capture needs its `onUpdate` row, and its `getValueFont` call count needs an explanation.

## Using the baseline

- A Phase 1 or later change may not raise the T0 (fenix3) peak above the recorded value (9.8 KB). Other tiers may grow when the feature needs it, as long as the peak stays below the memory limit with room to spare.
- Re-measure after every SDK update, because the compiler version changes code size.
- Compare optimization levels (`-O 2z`) in Phase 1.5 against this table.
