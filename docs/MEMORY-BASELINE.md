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

**fr965 (T3), multi-field (4-field) layout** (inferred from the code: the capture contains `getValueFont`, the font-fit loop that runs only in the multi-field branch). Three captures, 30 `compute` calls each (capture 3 with a couple of laps in it). The tool never shows an `onUpdate` row for the fr965 (not in any of the three), so there is no total per update; the rows below are the ones that exist. Totals in microseconds:

| Function | Capture 1 | Capture 2 | Capture 3 | Per update (range) | Calls |
|---|---:|---:|---:|---:|---:|
| `getValueFont` (inclusive) | 399062 | 466015 | 434362 | 13.3 to 15.5 ms | 240 |
| `Dc.drawText` | 342604 | 403632 | 375882 | 11.4 to 13.5 ms | 90 |
| `WatchUi.loadResource` | 36617 | 42467 | 38751 | 1.2 to 1.4 ms | 60 |
| `Properties.getValue` (settings) | 4536 | 4443 | 4199 | 0.14 to 0.15 ms | 180 |

The captures agree within about 17 %. The call count of `getValueFont` is 240 in all three, so it is not a measurement glitch: 8 per update, where the source calls it once per update. Hypothesis, not checked: the profiler counts the iterations of the font-fit loops as calls. In the source `getValueFont` only measures fonts and text and returns before `drawText` is called, so the rows do not contain each other and can be added: about 26 to 30 ms per update (`getValueFont` + `drawText` + `loadResource`), simulator time, without the time `onUpdate` spends in its own code. The time inside `getValueFont` is almost all in callees that the tool does not list (the listed callees add up to about 1 ms), probably `Dc.getTextWidthInPixels`.

What it shows:

- On T0, nearly two thirds of the update time is `loadResource`: the two label strings are loaded again on every update (about 1.3 ms of 2.0 ms). The same cost, about 1.2 ms per update, shows on the fr965. Loading them once (Phase 1.2 layout cache) is the largest single saving.
- Reading the settings on every update (6 calls) costs about 6 % on T0. Loading them once (Phase 1.1 `Settings`) removes it.
- On the fr965 in the multi-field layout the font-fit loop (`getValueFont`) and `drawText` dominate (3 `drawText` calls of about 3.8 to 4.5 ms each, 13 to 15 ms per update for `getValueFont`). Choosing the font only when the size or the text length changes (Phase 1.2) targets exactly that. The font-fit loop only exists in the multi-field path, so the single-field T0 numbers above do not include it.

Gaps: the two captures are different layouts and cannot be compared with each other. A fenix3 capture in the 4-field layout (the path with the font-fit loop) was considered and skipped by decision of the project owner; it is not needed to start Phase 1.2. Note the layout with every later capture. The fr965 has no `onUpdate` row in any capture, so use the rows above for it. One capture with laps (capture 3) also lists `Background.initialize` (4 calls) and `Background.draw` (1 call), although nothing creates a `Background`. Checked: captures 2 and 3 ran `tier-fr965.prg`, a scratch build whose `source/` files are identical to `master`, and neither the sources, the resources nor the generated `Rez.mc` instantiate the class. The rows stay unexplained and are low priority, because Phase 1.1 removes the class.

## Phase 1 progress

Peak memory in the simulator, measured by the project owner the same way as the baseline (four fields, simulation running). The exit criterion applies at the end of Phase 1; these rows show the trend.

| Step | fenix3 (T0) peak | Against baseline (9.8 KB) | Notes |
|---|---:|---:|---|
| Baseline (2.3.5 plus the getProperty fix) | 9.8 KB | | |
| Phase 1 PR 1 (split into Settings, Format, LapTracker, Layout) | 10.3 KB | +0.5 KB | The growth is at run time (the `.prg` file is smaller): more classes and objects. |
| Phase 1 PR 2 (layout cache, labels loaded once) | 11.0 KB | +1.2 KB | Measured with a build that prints `Lap Distance build: phase1-layout-cache` at start. |

The fenix3 four-field screenshot of that run shows the same overlapping digits as the fr965 (roadmap 7.2): the simulator draws over the previous frame because `onUpdate` never clears the screen. It is not caused by Phase 1.

### Scripted measurement (no simulator GUI)

The GUI peak can also be read from the console: a scratch copy of the code prints `System.getSystemStats().usedMemory` at the start of every `compute`, and `monkeydo` shows it. It is the memory in use between two updates (code plus objects, not the transient peak inside `onUpdate`), which is why it is a little below the GUI peak. The numbers follow the GUI numbers closely, so it is a usable proxy for comparing variants without a person at the simulator. fenix3, fresh simulator per run, no activity running, `compute` and `onUpdate` once per second:

| Build | Used, debug build (no `-r`) | Used, release build (`-r`) | `onUpdate` per call (release, simulator time) |
|---|---:|---:|---:|
| Before Phase 1 (`139ec52`) | 9.95 KB | 8.87 KB | 2.5 ms |
| PR 1 | 10.39 KB | 8.98 KB | 0.8 ms |
| PR 2 | 10.94 KB | 9.42 KB | under 1 ms (timer resolution 1 ms) |
| PR 3 (fixes: truncation, mile, reset, settings guards, size correction) | 11.34 KB | 9.77 KB | not measured again (the fixes do not touch the update path) |

Phase 2 (roadmap 2.3, second line with five contents), measured in bytes in one session with the same probe line for both builds (the probe line differs a little from the one above, so compare the two rows with each other, not with the table):

| Build (fenix3, release `-r`) | Used (bytes) | Growth |
|---|---:|---:|
| `master` after PR 3 (control) | 9712 | |
| 2.3: lap time, lap pace, current lap time, lap number | 11192 | +1480 |

The lap probe of roadmap 0.5 adds only empty calls to a normal build: 11288 bytes (+96) in the release build, 13384 in the debug build.

The debug build uses 12888 bytes. The setting does not change the number: the default (previous lap distance) and "current lap time" give the same value, because the code is the same and only the label differs. The growth is code, not data: two time formatters, the five-way content choice, the lap timer fields and the label loading. It is the largest step since the baseline and it takes the T0 release usage to 10.9 KB (1024-byte KB) of the 12 KB gate below.

What this shows:

- The release build the store ships uses about 1 KB less than the debug build the baseline was taken from. Compare like with like.
- The split into four classes costs about 0.1 KB (release); the cache work of PR 2 about 0.45 KB, spread over many small pieces (the cached label strings 0.09 KB, the cached "LL" text 0.04 KB, the build log function 0.02 KB, the layout cache check 0.03 KB; the rest is function and variable overhead).
- `-O 1` costs 0.1 KB more than `-O 2`; `-O 2z` gives the same result as `-O 2` for this code. A release build already uses `-O 2`.
- `onUpdate` takes about a third of the time after PR 1 and less than 1 ms after PR 2, against 2.5 ms before (timed with `System.getTimer`, which has a resolution of 1 ms).
- The simulator profiler listed the old function names (`getShowLastLapProp`, `getTextJustificationLValue`) for the PR 2 build although the console showed the PR 2 build was running, so do not use profiler row names from the simulator to tell which build ran.

## Using the baseline

- Gate for T0 (decision of the project owner, 2026-11-25, set at 12 KB when Phase 2 started): the memory in use on fenix3 in a release build (`-r`), read with the scripted measurement above, stays at or below 12 KB (12288 bytes, 75 % of the 16 KB limit). There is no official Garmin margin; 25 % free covers what the simulator does not show (firmware, longer translated strings, SDK updates, which move the numbers by some hundreds of bytes). Each data field app has its own heap, so other fields on the screen do not count. Features that do not fit are excluded from T0 by annotation. The earlier gates were the 9.8 KB GUI peak of the debug build (given up for the Phase 1 refactor) and 10 KB in a release build (replaced by this one). A later change needs a reason for every 0.1 KB it adds on T0. Other tiers may grow when the feature needs it, as long as the peak stays below the memory limit with room to spare.
- Re-measure after every SDK update, because the compiler version changes code size.
- Compare optimization levels (`-O 2z`) in Phase 1.5 against this table.
