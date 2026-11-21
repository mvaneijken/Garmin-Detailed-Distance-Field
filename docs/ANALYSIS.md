# Technical & Functional Analysis — Detailed Lap Distance Data Field

Snapshot: version 2.3.5 (commit `08f5269`), Connect IQ SDK 9.3.0, 154 products in `manifest.xml`.

Legend used throughout this document:

| Tag | Meaning |
|---|---|
| **[Verified]** | Observed directly in this repository's code/config, or confirmed by an authoritative source. |
| **[Strong]** | Supported by community-derived data (e.g. SDK device-file extracts) or multiple consistent sources, not yet verified against the local SDK. |
| **[Hypothesis]** | Plausible, must be tested (simulator or device) before acting on it. |
| **[Unknown]** | Not enough evidence; listed with the test that would resolve it. |

---

## 1. Functional baseline (what the field does today)

| Feature | Behaviour | Source |
|---|---|---|
| Current lap distance | `elapsedDistance − distanceAtLastLap`, shown with the large value font. | `compute()` |
| Previous lap distance | Optional second line, prefixed with `LL` / `LR`. | `showLastLap_prop` |
| Lap detection | `onTimerLap()` (manual + auto lap) and `onWorkoutStepComplete()` (structured workouts, CIQ ≥ 3.0). | View |
| Decimal precision | 4 bands (0–1, 1–10, 10–100, 100+ km/mi), 0–3 decimals each. | settings |
| Units | Metric / statute follows device `distanceUnits`. | `setDeviceSettingsDependentVariables()` |
| Label | Optional hide, to free space for a larger value font. | `hideLabel` |
| Font fitting | Starts at `FONT_NUMBER_THAI_HOT` and steps down until height and width fit; optional manual width/height correction (50–150 %). | `getValueFont()` |
| Positioning | Alignment derived from `getObscurityFlags()` (left/right/centre for round layouts). | View |
| Languages | English, Dutch. | `resources-*` |

Not present (relevant for the roadmap): lap time/pace, lap history, power, FIT recording, `onTimerReset` handling, lap-undo handling, multisport handling.

---

## 2. Architecture

**[Verified]** The entire field is one class (`XTDetailedDistanceDataFieldView`, ~590 lines) that mixes four responsibilities:

1. Settings access (`getPropertyValue`, read inside `onUpdate`).
2. Domain state (lap distances, lap events).
3. Formatting (`setDistStr`).
4. Layout + rendering (`onUpdate`, `getValueFont`, justification helpers).

Observations:

- `Background` drawable class (`XTDetailedDistanceDataFieldBackground.mc`) is never referenced — no layout XML uses it. Dead code that still costs code space. **[Verified]**
- Class-member initialisers call instance methods (`showLastLap = getShowLastLapProp()`, `lastLapDistanceString = setDistStr(...)`) before `initialize()` has run. Works today but is fragile and makes order-of-initialisation bugs likely. **[Verified]** (behaviour), **[Hypothesis]** (fragility on specific VMs).
- ~120 lines of commented-out debug code and a device part-number list at the end of the file. Not in the binary, but obscures the code.
- `getTextJustification()` and `getTextJustificationLValue()` are identical. **[Verified]**
- `getObscurityFlags()` is called up to ~10× per `onUpdate`. **[Verified]**
- Settings fallback `App.AppBase.getProperty(name)` calls an *instance* method through the class. `Application.Properties` only exists from API 2.4.0 **[Strong]**, so CIQ 1.x devices (fenix 3, FR230/235/630/920XT, vívoactive) always take this path. The idiomatic form is `Application.getApp().getProperty(name)`. Commit `3bb19dc` mentions fixing a crash here, so it probably works, but it must be covered by a test on a CIQ 1.x simulator target. **[Hypothesis]**

### Recommended target structure

Keep the class count low (every class and method costs memory on 16 KB devices), but separate pure logic from the `Dc`:

| Unit | Kind | Responsibility | Testable without simulator UI |
|---|---|---|---|
| `Settings` | module | Load all properties once (`initialize` + `onSettingsChanged`), sanitize (null → default, clamp 0–3). | yes |
| `LapTracker` | class | Lap boundaries, current/previous lap, de-duplication of lap events, reset; later: lap history ring buffer. | yes |
| `Format` | module (pure functions) | Distance → string, unit conversion. | yes |
| `Layout` | module | Compute font + positions **only** when size / obscurity / string length / settings change. | yes (inputs are numbers) |
| `View` | `DataField` | Wire events to `LapTracker`, call `Layout` when invalid, draw. | simulator |

Feature code above the 16 KB tier is isolated with build-time annotations (see §6), not with runtime `has` checks alone — runtime checks keep the code in the binary.

---

## 3. Correctness findings

| # | Finding | Impact | Status |
|---|---|---|---|
| C1 | Statute mile is hard-coded as **1610 m**; actual is **1609.344 m**. | 0.66 m error per mile; at 10 mi the display is 6.6 m off — relevant for a field whose purpose is precision. | **[Verified]** |
| C2 | No `onTimerReset()` handler; lap state is never cleared. | If a field instance survives into the next activity, previous-lap values leak. | **[Verified]** missing; **[Unknown]** whether the instance survives (test: finish/save, start new activity in the same profile, inspect values). |
| C3 | `onTimerLap()` and `onWorkoutStepComplete()` run identical code with no de-duplication. If both fire for the same boundary (e.g. a "lap button press" workout step), the second call sets previous lap ≈ 0 m. | Wrong "LL" value during workouts. | **[Hypothesis]** — forum reports say the two are separate events and that `onWorkoutStepComplete()` is not called for the final step. Test on device with (a) distance step, (b) lap-button step, (c) final step. |
| C4 | Lap undo (newer watches allow undoing a lap) has no CIQ event. | Field's lap distance diverges from the native lap after an undo. | **[Strong]** (open Garmin feature request `onTimerLapUndo`). Mitigation: on API ≥ 5.2.2 investigate `Activity.SplitInfo` **[Unknown]** as a native source of truth. |
| C5 | Multisport: no `onNextMultisportLeg` handling. | Unknown whether `elapsedDistance` resets per leg, which would yield negative lap distances. | **[Unknown]** — test with a triathlon/brick profile in the simulator. |
| C6 | Settings are not sanitized; a `null` precision would produce format string `"%.nullf"`. | Crash risk on corrupted/unsynced settings. | **[Hypothesis]** (defaults exist, but nothing guards). |
| C7 | `setDistStr` rounds (`%.3f`): 999.6 m shows `1.000` while still in the 0–1 band. | Cosmetic; displays distance not yet covered by ≤ 0.5 unit of the last digit. | **[Verified]**; decide truncate vs. round as a product decision. |

---

## 4. Efficiency (CPU / memory / battery)

`onUpdate()` runs once per second while visible. Per call it currently does: **[Verified]**

| Work per second | Why it is wasteful | Fix |
|---|---|---|
| 6–7 property reads (`Properties.getValue`) | Storage access + allocations; values only change on settings sync. | Read once; reload in `AppBase.onSettingsChanged()` and notify the view. |
| `Sys.getDeviceSettings()` | Allocates a `DeviceSettings` object every second. | Read in `initialize` / `onLayout`. |
| 1–2 `Ui.loadResource()` for labels | Allocates new strings every second. | Load once (they are small); on 16 KB devices consider loading on demand but cache. |
| Font fitting loop with `getTextWidthInPixels()` up to ~8 iterations | Text measurement is the most expensive call here. | Recompute only when `dc` size, obscurity, settings, or *string length* changes. Cache font per length. |
| ~10 `getObscurityFlags()` calls | Redundant native calls. | Compute in `onLayout()`; store. |
| String concatenation for "LL …" | New string each second. | Only rebuild on lap change. |

Expected outcome: lower peak memory (fewer temporaries, less GC pressure on 16 KB devices) and less CPU per update. Quantify with the simulator's *View Memory* / profiler before and after (baseline per tier, see roadmap phase 0).

Build-level levers: **[Strong]**

- Compiler optimisation `-O 2` (or `2z`/`2pz`): forum measurements show ~9 % smaller code vs. default `-O 1`; reported to be effective only on the command line, not in the jungle file.
- `prettier-extension-monkeyc` / `@markw65/monkeyc-optimizer`: source-level inlining, constant folding, dead-code removal; supports SDK 8.x per its changelog. Worth evaluating against the 16 KB budget.

---

## 5. Rendering (graphics and text)

- Text-only rendering with system fonts, transparent background (`setColor(fg, COLOR_TRANSPARENT)`), foreground chosen as the inverse of `getBackgroundColor()`. Simple and correct. **[Verified]**
- Layout is hard-coded per obscurity value (3, 6, 7, 9, 12, 15). Edge/Oregon/GPSMAP layouts often report obscurity `0` (interior fields) and fall into the generic branch — acceptable but untested. **[Hypothesis]**
- Font enumeration stepping (`valueFont - 1`) relies on the enum order `FONT_NUMBER_THAI_HOT → … → FONT_XTINY`; this is stable across SDKs but implicit. **[Verified]** (works), worth a comment.
- For the bar-chart roadmap item: `Dc.fillRectangle` (API 1.0) is sufficient; `Graphics.BufferedBitmap` exists from API 2.3.0 **[Strong]** but a buffer costs `width × height × bpp` RAM and is not needed for a few rectangles redrawn per second. Use a limited, high-contrast palette — MIP displays have 8/64 colours, AMOLED displays render saturated colours differently.

---

## 6. Device landscape & compatibility model

Data from the community extract [flocsy/garmin-dev-tools](https://github.com/flocsy/garmin-dev-tools) (derived from SDK device files `compiler.json`). **[Strong]** — verify locally (`~/.Garmin/ConnectIQ/Devices/<id>/compiler.json` → `appTypes[type=datafield].memoryLimit`, `partNumbers[].connectIQVersion`).

| Tier (proposal) | Data-field memory | Max CIQ version | Example devices in manifest |
|---|---|---|---|
| **T0** | 16 KB | 1.3–1.4 | fenix 3 / 3 HR, FR230, FR235, FR630, FR920XT, vívoactive |
| **T1** | 32 KB | 2.4 – 3.4 | vívoactive HR, FR735XT, Approach S60 (2.4); fēnix 5, FR935, fēnix Chronos, FR645, vívoactive 3 (3.0–3.1); FR245, fēnix 6, Venu, FR55 (3.2–3.4) |
| **T1b** | 32 KB | 5.x–6.0 | Instinct E 40 mm (6.0.2) — new device, old memory budget |
| **T2** | 64–128 KB | 3.3 – 6.0 | FR645 Music (64 KB), fēnix 5 Plus, FR945, fēnix 8 47 mm, **fēnix 9 Pro 47 mm (6.0.3)** |
| **T3** | 256 KB | 5.2 – 6.0 | fēnix 7, FR255, FR965, FR70, FR170 |

Key implications:

- **Memory is not monotonic with age or API level.** fēnix 6 (32 KB) and Instinct E (32 KB) are as constrained as fēnix 5; fēnix 8/9 (128 KB) have less than fēnix 7 (256 KB). Feature gating must be on *memory tier* and *API level* separately.
- **API-level gates relevant to this project** (class-level minimums from the same extract): `Application.Properties` 2.4.0, `Activity.WorkoutStepInfo` / `getCurrentWorkoutStep` 3.2.0, `Graphics.BufferedBitmap` 2.3.0, `FitContributor` 1.3.0, `Ant.GenericChannel` 1.0.0 (class), `BluetoothLowEnergy` 3.1.0, `Activity.SplitInfo` 5.2.2. Member-level levels (e.g. `onWorkoutStepComplete`, `Info.currentPower`) are not in that extract — confirm in the API docs.
- **fēnix 5 / FR935 / FR645 / vívoactive 3 (max 3.0–3.1)** get `onWorkoutStepComplete` but **not** `WorkoutStepInfo` (3.2.0): workout-intensity highlighting cannot work there.
- Connect IQ System 9 / API 6.0 was introduced with SDK 9.1 (March 2026); SDK 9.3 added microphone/speaker/LTE APIs (fēnix 8 Pro, fēnix 9, MARQ Gen 3). None of those are relevant for this field.

### Mechanism for "support everything, add features where possible"

1. Annotate optional code: `(:t1)`, `(:t2)` … or feature-named (`(:power)`, `(:lapchart)`).
2. In `monkey.jungle`: `base.excludeAnnotations = power;lapchart` and per device/tier override, e.g. `fenix7.excludeAnnotations = ` (empty → include all).
3. Generate those jungle lines with a script from the local device files so new devices are classified automatically when the SDK is updated.
4. Keep `has :symbol` checks only for firmware variance *within* a tier.

---

## 7. Testability

- **[Verified]** No tests exist; `.vscode/launch.json` already contains a "Run Tests" configuration.
- Connect IQ supports unit tests via `(:test)` annotated functions with `Toybox.Test` and `monkeydo <prg> <device> -t` against the simulator. Tests are compiled into a separate build (`--unit-test`), so they cost nothing in release binaries. **[Strong]**
- What to test once logic is extracted: formatting per band and precision (incl. 0, boundaries 999.5 m / 1 km / 10 km, statute), lap tracker sequences (lap, step-complete, duplicate events, reset, negative deltas), settings sanitisation, layout math for each obscurity value and representative screen sizes.
- Device-level behaviours (C2–C5) cannot be unit tested; capture them as a manual test script with a short results table per firmware.

---

## 8. Build, repository hygiene, CI/CD

| Finding | Status |
|---|---|
| Azure pipeline builds `MY_APP.iq` but publishes `$(name).iq` → the publish step points at a file that does not exist. | **[Verified]** (by reading `azure-pipelines.yml`; not executed) |
| Pipeline pins SDK **7.4.3**, repository targets **9.3.0** → CI does not build what is released. | **[Verified]** |
| Pipeline installs OpenJDK 8; check the Java version required by SDK 9.x. | **[Unknown]** |
| Signing key is pulled from Key Vault and written to disk — fine; ensure the agent is ephemeral (it is, Microsoft-hosted). | **[Verified]** |
| `bin/**` is in `.gitignore` but `bin/*.prg`, `*.debug.xml` are tracked. `.gitignore` starts with a UTF-8 BOM, which can break the first pattern. | **[Verified]** (tracked files), **[Hypothesis]** (BOM effect) |
| `build/<version>/*.iq` binaries committed: 24 MB of history growth. Use GitHub Releases for artefacts. | **[Verified]** |
| `manifest.xml` header says "generated, do not edit" but it is edited by hand / VS Code — fine, but sort/regenerate the product list from the SDK device list in CI to avoid drift. | **[Verified]** |

### Recommended CI/CD (GitHub Actions, since the code lives on GitHub)

1. **Setup:** install JDK + Connect IQ SDK + device files headless (community `connect-iq-sdk-manager-cli`; device download requires a Garmin developer login stored as secret) — cache the SDK directory.
2. **Static checks:** `monkeyc` with `-l 2`/`-l 3` (type checking) and `-w` for every PR.
3. **Build matrix:** compile for one representative device per tier (fenix3, fenix5, fenix6, instincte40mm, fenix847mm, fenix9pro47mm, fr965) and fail on build errors; record `.prg` size per device as a trend.
4. **Unit tests:** run simulator under `xvfb-run`, `monkeydo … -t` on at least a T0 and a T3 device.
5. **Release (tag):** `monkeyc -e -r -O 2` → `.iq`, attach to a GitHub Release. Store upload stays manual (no public store-upload API is known **[Unknown]**).

---

## 9. Feasibility: third-party sensors (Stryd)

| Option | How | Pros | Cons / risks | Evidence |
|---|---|---|---|---|
| **A. Native power via `Activity.Info.currentPower`** | Pair Stryd on the watch as ANT+ *power pod*/power sensor; field reads `info.currentPower` in `compute()`. | No permissions, minimal code (fits T0), works with any standard power source. | Depends on pairing; Garmin's own wrist/HRM running power is reportedly **not** exposed via `currentPower`; firmware-specific bugs reported (e.g. FR965). | Stryd help centre: "connect Stryd as an ANT+ power pod" for third-party fields, no guarantee **[Strong]**; forum bug report on native power **[Strong]** |
| **B. Direct ANT+ via `Ant.GenericChannel`** | Field opens its own ANT channel to the Stryd (power profile). | Independent of native pairing; can show Stryd and Garmin power side by side. | Needs `Ant` permission, more code/RAM (exclude from T0), channel search/pairing UX, Stryd ANT ID setting, no native FIT power. Stryd's proprietary profile (form power, LSS, etc.) is not publicly documented. Device type commonly used: 11 (bike power) — **[Hypothesis]**, verify against ANT+ profile. | Forum + SDK MoxyField sample pattern **[Strong]** |
| **C. BLE via `BluetoothLowEnergy`** | Custom BLE GATT client. | Only option for BLE-only sensors. | API 3.1.0+; availability for *data fields* **[Unknown]**; more code, pairing complexity. | — |

Constraint to keep in mind: Stryd recommends running its own *Stryd Zones* field alongside third-party fields for PowerCenter sync. That consumes a CIQ slot, which partly defeats the "save CIQ slots" goal. Most watches allow 2 CIQ fields per activity; fēnix 8 advertises 4 but users report 2 effective in some cases, and the per-activity developer-FIT-field budget (16) is separate **[Strong]**.

**Conclusion:** Stryd support is feasible. Start with option A (cheap, all tiers). Option B only if a concrete need appears that A cannot meet.

---

## 10. Feasibility: lap bar chart with workout highlighting

- Lap history: a fixed-size ring buffer (e.g. 8–10 laps × distance, duration, intensity, optional avg power) costs a few hundred bytes — feasible on T1+; on T0 only after measuring.
- Lap duration from `info.timerTime` at lap boundaries **[Strong]**; pace = duration / distance.
- Workout intensity: `Activity.getCurrentWorkoutStep()` → `WorkoutStepInfo.intensity` (active / rest / warm-up / cool-down / recovery / interval) from API 3.2.0 **[Strong]**. Capture intensity *during* the step in `compute()` and assign it when the lap closes; whether `getCurrentWorkoutStep()` already returns the *next* step inside `onWorkoutStepComplete()` is **[Unknown]**.
- Colour semantics: fastest/slowest among comparable laps (compare only same-intensity laps in workouts, otherwise recovery laps are always "slowest").
- Rendering cost: N `fillRectangle` calls behind the text — negligible; must keep text contrast (draw bars dimmed or in the lower band).
