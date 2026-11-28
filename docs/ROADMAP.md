# Roadmap — Detailed Lap Distance Data Field

Guiding constraints (from the project owner):

1. **Keep every device the SDK supports.** No device is dropped to make room for a feature.
2. **Add features per capability**, gated by *measured* memory and API level (see `ANALYSIS.md` §6). Every tier, including T0, gets every feature that fits.
3. **Stay efficient**: no regression in peak memory on the 16 KB tier (T0).

Each phase ends in a releasable version. Phases 0–1 deliberately ship no new user-facing features: they create the safety net that the feature phases depend on.

---

## Phase 0 — Safety net & baseline (→ 2.3.6, no functional change)

| # | Item | Done when |
|---|---|---|
| 0.1 | GitHub Actions per `docs/CI-CD.md`: `/validate` PR validation (export + tier builds + unit tests), draft release, approval-gated publish. Azure pipeline removed. | **Done**: `/validate` is green and the release dry-run (version 2.3.6, discarded afterwards) ran green from signed build to draft release; the draft assets download with `gh api` and match the SHA-256. Open items stay in `docs/CI-CD.md` (the first real "Publish Release" run, the simulator in CI). |
| 0.2 | Repo hygiene: untrack `bin/` and fix `.gitignore`; move `build/*.iq` to GitHub Releases and create the missing releases 2.3.2–2.3.5. | **Done**: the `.iq` files of 2.2.7 to 2.3.5 (and the 2.3 `.prg`) are release assets, the missing releases exist, `build/` is untracked and ignored. `git ls-files bin build` is empty. The old blobs stay in the git history (about 24 MB, accepted). |
| 0.3 | Device tier script: read `compiler.json` of all installed devices → CSV (id, CIQ version, datafield memory) + generated jungle `excludeAnnotations` lines. | **Implemented**: `tools/Get-DeviceTiers.ps1` writes `docs/device-tiers.csv` and `docs/device-tiers.jungle.txt` (SDK 9.3.0: T0 9, T1 33, T1b 3, T2 57, T3 51 devices). Re-run it on every SDK update. The jungle lines are a proposal until code carries the `t1`/`t2`/`t3` annotations. |
| 0.4 | Memory/CPU baseline: peak memory per tier device in the simulator (single + 4-field layout). | **Done for memory** (peak memory per tier device, single and 4-field): `docs/MEMORY-BASELINE.md`. T0 (fenix3) peak 9.8 KB of 16 KB; the other six tier devices 11.1 to 12.9 KB; no difference between layouts. Update time (simulator profiler) is recorded for fenix3 and fr965 in the same file; on T0 about 65 % of `onUpdate` is `loadResource`. fr965 in the 4-field layout: three captures (the tool shows no `onUpdate` row for it). The fenix3 4-field capture is skipped by decision of the project owner (not worth the effort); Phase 1.2 is judged on the numbers above. |
| 0.5 | Manual device test script for lap behaviour (C2–C5 in the analysis): auto lap, manual lap, workout distance step, lap-button step, final step, lap undo, save + new activity, multisport. | **Protocol written**: `docs/LAP-TEST-PROTOCOL.md`, including the automation plan: the lap logic becomes unit tests in Phase 1.3 (CI); what the firmware sends can only be tested on a device, made cheap with a probe build, a device log and a FIT comparison script (**written**: `source/Probe.mc` with `probe.jungle`, `tools/probe/Build-LapProbe.ps1` and `tools/probe/compare_lap_probe.py`, with a run sheet in the protocol; the device runs are the owner's and the results are pending). Done when the results are recorded for at least fēnix 9 Pro + one older device/simulator. |

## Phase 1 — Refactor for efficiency and testability (→ 2.4.0)

| # | Item |
|---|---|
| 1.1 | Extract `Settings` (load once + `onSettingsChanged`), `Format`, `LapTracker`, `Layout` (see analysis §2). Remove `Background` class, duplicate justification function, commented code. **Implemented** (Phase 1 PR 1, no behaviour change): `source/Settings.mc`, `Format.mc`, `LapTracker.mc`, `Layout.mc`; `Layout` recomputes on every update until 1.2 adds the cache. |
| 1.2 | Layout cache: recompute fonts/positions only on size/obscurity/settings/string-length change. Also load the label strings once: `loadResource` is about 65 % of the T0 update time (see `docs/MEMORY-BASELINE.md`). **Implemented** (Phase 1 PR 2): `Layout` is recomputed only after `onLayout`, a settings change, or a change in the length of the value text; the two label strings are loaded once; the "LL" text is rebuilt only when the previous lap, the unit or a setting changes; the device unit is still read every update (it can change while the field runs and no event reports it, about 1 % of the T0 update time), but the "LL" text is rebuilt only when it changed. To measure: update time and peak memory on fenix3 against the baseline. |
| 1.3 | Unit tests (`(:test)`) for Format, LapTracker, Settings sanitisation, Layout math; run in CI under `xvfb`. The LapTracker tests replay the scenarios S1–S8 of `docs/LAP-TEST-PROTOCOL.md` as event sequences. **Started** (Phase 1 PR 1): 16 tests in `source/*Test.mc` for Format, LapTracker (S1 to S5), Layout (fake draw context) and Settings; they describe today's behaviour, and each fix of 1.4 changes the tests it touches. S7 (needs `onTimerReset`) and S8 follow with 1.4. The CI image runs them (see `docs/CI-CD.md`). |
| 1.4 | Fixes: mile = 1609.344 m (C1), `onTimerReset` (C2), lap-event de-duplication based on phase-0 findings (C3), settings null/clamp guards (C6), truncate instead of round the last decimal (C7/D3), use `Application.getApp().getProperty()` for CIQ 1.x. **Implemented** (Phase 1 PR 3), except C3: C1 (`Format.MILE_METERS`), C2 (`onTimerReset`), C6 (`Settings.clamp`), C7 (truncation with a float correction; tests at 999/999.6/1000/1001/9999/10000 m and the mile), `getProperty` was already fixed. Also fixed: the size correction settings (50 to 150 %) never worked (integer division, and the width factor cancelled out). C3 waits for the device test 0.5. |
| 1.5 | Evaluate `-O 2z` and the Prettier Monkey C optimizer; keep whichever gives the lowest T0 peak memory. `-O 2z` is measured: same as `-O 2`, which a release build uses already (see `docs/MEMORY-BASELINE.md`). The Prettier optimizer is skipped by decision of the project owner (a source-level build step for an unknown gain). |

Exit criterion: T0 memory in a release build at or below 12 KB (changed on 2026-11-25 from "at or below the 9.8 KB baseline", first to 10 KB and then to 12 KB when Phase 2 started; see `docs/MEMORY-BASELINE.md`), all tests green. Phase 1 is done except C3, which waits for the device test 0.5. The release of 2.4.0 is not made on its own: the owner publishes to Garmin after the Phase 2 work, and the internal release and the version bump follow then.

## Phase 2 — Lap model (→ 2.5.0, foundation for phases 3–4)

| # | Item | Tier/API gate |
|---|---|---|
| 2.1 | Lap history ring buffer: distance, duration (`timerTime`), intensity, (later) avg power. Size configurable at build time per tier. **Implemented** (Phase 2 PR 2): `LapHistory` (`source/LapHistory.mc`, parallel arrays, newest lap first, a lap with under 1 m and under 1 s is not stored: C3 guard) and the `LapLog` module the view calls. The size follows the memory limit at run time (12 laps up to 32 KB, 50 above), which needs no per-tier constant. T1 and above only: the code carries the `t1` annotation and T0 devices get the `t0` no-op twins (+80 bytes on fenix3). The per-device tier lines are generated into `monkey.jungle` and `probe.jungle` by `tools/Get-DeviceTiers.ps1 -UpdateJungles`. Nothing shows the history yet: Phase 4 and 2.3 use it. | T1+ (T0 only if budget allows) |
| 2.2 | ~~Capture workout intensity via `getCurrentWorkoutStep()`~~ **Not possible in a data field**: `Activity.getCurrentWorkoutStep()` and `getNextWorkoutStep()` throw `OperationNotAllowedException` when called from a data field app (SDK 9.3.0 documentation; found by the Codex review of PR #24). A data field only gets `onWorkoutStarted` and `onWorkoutStepComplete`. **Reworked and implemented** (Phase 2 PR 3): every finished lap in the history stores *why* it was made: the lap trigger of `onTimerLap2(info)` (API 5.2.2, DataField.LAP_TRIGGER_*: manual, time, distance, workout step, ...), a marker for `onWorkoutStepComplete`, or null on watches that do not say. The `lapinfo` annotation (API 5.2.2) is generated per device (`tools/Get-DeviceTiers.ps1`). The probe logs `lap2_<trigger>` events, so the device test 0.5 also shows the trigger of each lap. Whether an active and a recovery step can be told apart is open: see 4.3. | API ≥ 5.2.2 for the trigger (`(:lapinfo)`) |
| 2.3 | Optional second-line content: previous lap distance (today) / lap time / lap pace — one setting, not three. **Implemented** (Phase 2 PR 1): setting "Second line shows" with previous lap distance (default), previous lap time, previous lap pace, current lap time and current lap number; `LapTracker` keeps the timer time and the lap number; the pace is rounded to a second, times are cut. On T0 it costs 1.5 KB of release memory (see `docs/MEMORY-BASELINE.md`). | all |

## Phase 3 — Stryd without the Stryd Zones field (→ 2.6.x)

Goal (owner decision): read **all** Stryd metrics in this field, so the *Stryd Zones* field is no longer needed on the watch. No comparison with Garmin native running power.

Metric availability by transport (details and evidence levels in `ANALYSIS.md` §9):

| Metric | Source | Confidence |
|---|---|---|
| Power | ANT+ power profile → `Activity.Info.currentPower` (native pairing) or own `Ant.GenericChannel` | Strong |
| Pace / speed, distance, cadence | ANT+ foot pod (SDM) → native `Activity.Info` when Stryd is the speed/distance source | Strong |
| Ground contact time, vertical oscillation | ANT+ Running Dynamics profile → `AntPlus.RunningDynamics` (API 2.4.0) — only if Stryd broadcasts that profile | Hypothesis |
| Form power, air power, leg spring stiffness | Stryd proprietary ANT+/BLE profile, no public specification | Unknown |

| # | Item | Tier/API gate |
|---|---|---|
| 3.1 | **Spike (go/no-go):** capture what the owner's Stryd actually broadcasts: ANT+ device types/pages (ANT USB stick + ANTware/SimulANT+ or similar) and BLE services (nRF Connect). Output: table of profiles, pages, data and update rate. | — (on owner's hardware) |
| 3.2 | Power via `Activity.Info.currentPower`; current, 3 s/10 s/30 s rolling, lap average. Stryd paired natively as power sensor. **Implemented** (Phase 3 PR 1): second-line contents power, 3 s, 10 s and 30 s power and lap average power (`SensorLine`, `PowerStats`; the lap average is also stored per lap in the history). Decision: all of it is T1 and above, and the setting list of a T0 watch offers only the first five contents (see the resource split in `docs/MEMORY-BASELINE.md`): the first version with the sensor code on T0 took the fenix3 release build to 12568 bytes (over the 12 KB gate); with the twins it is 11912. | all tiers; rolling windows T1+ |
| 3.3 | Pace/cadence/distance via native foot-pod pairing (no code beyond selecting the metric). **Implemented** (Phase 3 PR 1) as the second-line contents cadence and current pace from `Activity.Info`; distance already comes from the watch. T1 and above. | all |
| 3.4 | GCT / VO via `AntPlus.RunningDynamics`, if 3.1 shows that the Stryd broadcasts this profile. | API ≥ 2.4.0, T1+ |
| 3.5 | Form power / air power / LSS via own `Ant.GenericChannel` decoder — **only if 3.1 shows they can be decoded reliably** and the legal/terms check passes. Fallback: these metrics remain available in Stryd PowerCenter through the pod's offline sync (no watch field needed). | T1+/T2 (measure) |
| 3.6 | Record Stryd metrics to the FIT file via `FitContributor` so they reach Garmin Connect / third parties without Stryd Zones. Mind the 16-developer-field per-activity budget shared with other CIQ fields. | API ≥ 1.3.0, T1+ |
| 3.7 | **Started**: `docs/POWER-AND-STRYD.md` (what the field shows, pairing hints to confirm on a watch, what is not replaced). User documentation: pairing (power + foot pod), ANT ID, offline sync for PowerCenter, what Stryd Zones features are *not* replaced (zones sync, Stryd workouts). | — |

## Phase 4 — Lap bar chart background (→ 2.7.0)

Owner decision: **bar height = lap distance.**

| # | Item | Tier/API gate |
|---|---|---|
| 4.1 | Bar chart of the last N laps behind the value; bar height = lap distance, current lap as a growing bar. Scale = longest lap in view. **Implemented** (Phase 4 PR 1): setting "Show lap bar chart" (default off), `LapChart` and `LapChartModel` (`source/LapChart.mc`): 4 to 12 bars (about 16 pixels each), oldest left, the lap in progress grows on the right, drawn with `fillRectangle` before the text. T1 and above (it reads the lap history); T0 keeps an empty twin. Not looked at on a screen yet (see the hand-over list). | all tiers where memory allows (measure on T0): T1 and above |
| 4.2 | Colour = pace rank: fastest / slowest lap highlighted. **Implemented** (Phase 4 PR 1) among the finished laps in view (green fastest, red slowest, muted greys otherwise, darker tones on a white background; no colour when all laps have the same pace, as with a fixed auto lap). The ranking per workout intensity is not possible (see 4.3). | T0+ (pace needs lap duration): T1 and above |
| 4.3 | ~~Workout mode: active vs. recovery visually distinct, via `WorkoutStepInfo.intensity`~~ **Not possible**: a data field cannot read the workout step (`getCurrentWorkoutStep` throws in a data field app, see 2.2). The lap trigger stored per lap (2.2) says why a lap was made, not whether the step was active or recovery. Open for the owner: drop it, or mark laps that ended on a workout step. | API ≥ 3.2.0 |
| 4.4 | Only in layouts with enough height (single field, large half-screen); auto-disable in small fields. Palette per display type (MIP 8/64 colours, AMOLED). **Implemented** (Phase 4 PR 1): the chart needs a field of at least 110 x 90 pixels (`LapChart.fits`), a smaller field draws no bars. The palette follows the background color the watch sets (grey and green/red tones for black, darker ones for white); a separate palette for 2-color (Instinct) and AMOLED screens is not made: open question for the owner. | all |

Note: with fixed-distance auto-lap every completed bar has the same height; then the chart carries information only through colour and the growing current bar. That is inherent to the chosen metric.

## Phase 5 — Optional / evidence-driven

Only start when a concrete need is confirmed:

- `Activity.SplitInfo` (API 5.2.2+) as native lap source of truth to handle lap undo.
- BLE transport for Stryd (only if ANT+ is insufficient; data-field availability of `BluetoothLowEnergy` is unknown).
- Additional languages.

## Phase 6 — Native text style on map pages (backlog, not scheduled)

Reported 2026-11-23 on a fēnix 9 Pro 47mm (data screen background setting: black): on a map page the field is drawn with white text on the light map, so it is hard to read, while the native fields there use black text with a light halo (shading).

Findings so far (from the SDK docs; not yet confirmed on a device):

- `onUpdate` chooses the text colour from `DataField.getBackgroundColor()` (white on black, black otherwise). The API documents that call only as "the current Data Field background color", i.e. the colour configured for the data screen. It says nothing about the pixels behind the field, so on a map page a black screen setting yields white text on a light map. What the device actually returns on a map page is unverified and the simulator cannot show a map page.
- The Connect IQ API has no "match the native style" call and no text outline: `Dc.setStroke` applies to primitives only. A halo has to be drawn by hand (the text repeated with 1 px offsets in the contrasting colour, then the real text on top).
- The big digits already use `FONT_NUMBER_THAI_HOT`, the same family as the native large numeric fields. Other faces would need `Graphics.getVectorFont` (API 4.2.1+; its `:font` and `:scale` options need 5.1.0+), whose face names are device specific and not listed in the SDK files.

| # | Item | Done when |
|---|---|---|
| 6.1 | On-device probe: show the value of `getBackgroundColor()` (and the obscurity flags) in the field on a map page, with the screen background set to black, white and automatic. **Tooling ready**: the probe build logs `P,bg,<clock>,<color>,<obscurity>,0,0,0` whenever one of them changes (`Probe.background`); run it on a map page with the three background settings (`docs/LAP-TEST-PROTOCOL.md` describes the probe; the owner runs it) | Values recorded in `docs/`. |
| 6.2 | Settings: "Text colour" (Auto, Black, White) and "Halo" (on/off). Auto keeps today's behaviour unless 6.1 shows a better signal. **Implemented** (Phase 6 PR 1), T1 and above: the owner can set the text colour by hand for a map page. | Settings load through the Phase 1 `Settings` class. |
| 6.3 | Halo drawing in `Layout`/`Format` code paths, with the number of `drawText` calls per string chosen from a measured cost. **Implemented** as `TextStyle.drawHalo`: the line drawn four times, one pixel diagonally, in the opposite colour, then the text on top (4 extra `drawText` calls per line, off by default, T1 and above). The cost per update is not measured on a watch (the simulator profiler is unreliable, see `docs/MEMORY-BASELINE.md`): open for the owner. | Peak memory and update time per tier within the Phase 0 baseline (D2: gate by measurement, never drop a device). |
| 6.4 | Compare against the native look on a map page and adjust the halo width and colours. Evaluate vector fonts only if the digits still differ visibly; gate them on API 4.2.1+ and keep the bitmap fonts on older devices. **Open: needs a screenshot or photo from a watch** (not possible from here). | Photo or screenshot comparison recorded; owner sign-off. |

Depends on Phase 1 (settings loaded once, layout cache) and the Phase 0 memory baseline. It also helps Phase 4, because text over the bar chart needs the same legibility.

## Phase 7 — Odd-layout devices and simulator overdraw (backlog, not scheduled)

Reported 2026-11-24 from simulator runs by the project owner (screenshots, not yet confirmed on a device):

- **Instinct E 40 mm (`instincte40mm`)**: the data field area is not laid out like on the other devices. In the simulator the field is a square area with the round subscreen overlapping its upper-right corner, and the value and the second line (`LL ...`) are drawn into the lower part and clipped on the right. The field has no idea about the subscreen: its layout decisions use only the size from the device context and `DataField.getObscurityFlags()`.
- **How many devices**: the SDK device descriptors (`simulator.json`) of 9 of the 153 manifest devices contain a `subscreen`: `descentg1`, `instinct2`, `instinct2s`, `instinct2x`, `instinct3amoled45mm`, `instinct3amoled50mm`, `instinct3solar45mm`, `instincte40mm`, `instincte45mm`. Other shapes may need the same treatment; item 7.1 finds out.
- **fr965 4-field layout**: in the simulator three of the four fields show digits drawn on top of each other and bold-looking labels; the fourth field and the single-field layout are drawn correctly. Hypothesis (from the code, not tested): `onUpdate` never clears its background (the `Background` drawable is unused, and the SDK sample data fields call `dc.clear()`), so a simulator that does not clear the field area between updates shows every update on top of the previous one, and repeated anti-aliased text looks bold. Since version 2.3.2 the field deliberately draws on a transparent background, so a plain `dc.clear()` could cost the transparency on map pages (Phase 6). It may be a simulator-only effect.

| # | Item | Done when |
|---|---|---|
| 7.1 | Inventory: for each device with a `subscreen` (and any other device whose data field area is not a plain rectangle), record in the simulator the field size, the obscurity flags and where the subscreen overlaps the field. | Table in `docs/`. |
| 7.2 | fr965 overlap: reproduce it in the simulator, then test the hypothesis with a temporary background clear. Check a real 4-field data screen on a fēnix 9 Pro or fr965 if possible. | Cause recorded: simulator only, or a field bug with a fix that keeps the transparent background where it matters. **Simulator part done (2026-11-24):** the fr965 4-field overlap reproduces with `master`, and a build with `dc.setColor(Gfx.COLOR_TRANSPARENT, getBackgroundColor()); dc.clear();` at the start of `onUpdate` does not show it. So the missing clear is the cause in the simulator. **Device part (2026-11-24):** the owner tested a 4-field data screen on the fēnix 9 Pro 47 mm and does not see the overlap, so it is a simulator-only effect for now and the code stays unchanged. Revisit only if the overlap ever shows on a real watch; then the open question is what an opaque clear does to the transparent look on map pages. |
| 7.3 | Layout rules for subscreen devices: the `Layout` class (Phase 1.1) works with a usable rectangle that excludes the subscreen overlap and places the value and the second line inside it. Gate by device capability (jungle annotation), never drop a device (D2). | Instinct devices render correctly in the simulator; peak memory and update time within the Phase 0 baseline. |
| 7.4 | Keep one simulator screenshot per odd-layout device in `docs/` as a regression reference. | Screenshots committed. |

Depends on Phase 1 (`Layout`, layout cache) and the Phase 0 baseline. Item 7.2 does not depend on Phase 1 and can run any time.

---

## Decisions (recorded 2026-11-21)

| # | Question | Decision |
|---|---|---|
| D1 | Bar metric | Lap distance (colour carries pace rank / intensity). |
| D2 | T0 (fēnix 3 generation) frozen? | No — every feature is attempted on every tier; gate only on measured memory and API level. |
| D3 | Last-decimal rounding | Follow athletics (World Athletics / Atletiekunie) convention: never display more than was achieved → **truncate** (round down). See `ANALYSIS.md` C7. |
| D4 | Stryd scope | All Stryd metrics without the Stryd Zones field; no Garmin-vs-Stryd comparison. |
