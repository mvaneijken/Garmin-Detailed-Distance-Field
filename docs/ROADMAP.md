# Roadmap — Detailed Lap Distance Data Field

Guiding constraints (from the project owner):

1. **Keep every device the SDK supports.** No device is dropped to make room for a feature.
2. **Add features per capability**, gated by memory tier *and* API level (see `ANALYSIS.md` §6).
3. **Stay efficient**: no regression in peak memory on the 16 KB tier (T0).

Each phase ends in a releasable version. Phases 0–1 deliberately ship no new user-facing features: they create the safety net that the feature phases depend on.

---

## Phase 0 — Safety net & baseline (→ 2.3.6, no functional change)

| # | Item | Done when |
|---|---|---|
| 0.1 | GitHub Actions: build matrix (one device per tier), type check, warnings as errors. Retire or fix the Azure pipeline (artefact name, SDK 7.4.3 vs 9.3.0). | PR builds green for fenix3, fenix5, fenix6, instincte40mm, fenix847mm, fenix9pro47mm, fr965. |
| 0.2 | Repo hygiene: untrack `bin/`, remove BOM from `.gitignore`, move `build/*.iq` to GitHub Releases. | `git ls-files bin build` empty; releases contain the `.iq` files. |
| 0.3 | Device tier script: read `compiler.json` of all installed devices → CSV (id, CIQ version, datafield memory) + generated jungle `excludeAnnotations` lines. | Script in `tools/`, output committed, re-run on SDK update. |
| 0.4 | Memory/CPU baseline: peak memory per tier device in the simulator (single + 4-field layout). | Table in `docs/` — the budget all later phases are measured against. |
| 0.5 | Manual device test script for lap behaviour (C2–C5 in the analysis): auto lap, manual lap, workout distance step, lap-button step, final step, lap undo, save + new activity, multisport. | Results recorded for at least fēnix 9 Pro + one older device/simulator. |

## Phase 1 — Refactor for efficiency and testability (→ 2.4.0)

| # | Item |
|---|---|
| 1.1 | Extract `Settings` (load once + `onSettingsChanged`), `Format`, `LapTracker`, `Layout` (see analysis §2). Remove `Background` class, duplicate justification function, commented code. |
| 1.2 | Layout cache: recompute fonts/positions only on size/obscurity/settings/string-length change. |
| 1.3 | Unit tests (`(:test)`) for Format, LapTracker, Settings sanitisation, Layout math; run in CI under `xvfb`. |
| 1.4 | Fixes: mile = 1609.344 m (C1), `onTimerReset` (C2), lap-event de-duplication based on phase-0 findings (C3), settings null/clamp guards (C6), use `Application.getApp().getProperty()` for CIQ 1.x. |
| 1.5 | Evaluate `-O 2z` and the Prettier Monkey C optimizer; keep whichever gives the lowest T0 peak memory. |

Exit criterion: T0 peak memory ≤ baseline, all tests green.

## Phase 2 — Lap model (→ 2.5.0, foundation for phases 3–4)

| # | Item | Tier/API gate |
|---|---|---|
| 2.1 | Lap history ring buffer: distance, duration (`timerTime`), intensity, (later) avg power. Size configurable at build time per tier. | T1+ (T0 only if budget allows) |
| 2.2 | Capture workout intensity via `getCurrentWorkoutStep()`; assign on lap close. | API ≥ 3.2.0 (`(:workoutinfo)`) |
| 2.3 | Optional second-line content: previous lap distance (today) / lap time / lap pace — one setting, not three. | all |

## Phase 3 — Power / Stryd v1 (→ 2.6.0)

| # | Item | Tier/API gate |
|---|---|---|
| 3.1 | Read `Activity.Info.currentPower`; show current, 3 s/10 s rolling and lap-average power as a selectable slot. | all tiers; rolling windows T1+ |
| 3.2 | Lap average power stored in lap history (feeds phase 4). | T1+ |
| 3.3 | Document user setup: pair Stryd as ANT+ power pod; implications for *Stryd Zones* and CIQ slot usage. | — |
| 3.4 | Device validation: Stryd on fēnix 9 Pro and one older watch; confirm `currentPower` is non-null with Stryd and with native Garmin power only. | — |

## Phase 4 — Lap bar chart background (→ 2.7.0)

| # | Item | Tier/API gate |
|---|---|---|
| 4.1 | Bar chart of the last N laps behind the value (metric: pace — or distance/power, setting). Fastest/slowest coloured; current lap as growing bar. | T1+ ; colour palette per display type (MIP/AMOLED) |
| 4.2 | Workout mode: highlight laps by intensity (active vs. recovery); fastest/slowest computed only among same-intensity laps. | API ≥ 3.2.0 |
| 4.3 | Only in layouts with enough height (single field, large half-screen); auto-disable in small fields. | all |

## Phase 5 — Optional / evidence-driven

Only start when a concrete need is confirmed:

- Direct Stryd connection via `Ant.GenericChannel` (option B in analysis §9) — if native pairing is insufficient on target devices. T2+.
- FIT recording of lap power/pace via `FitContributor` — mind the per-activity developer-field budget.
- `Activity.SplitInfo` (API 5.2.2+) as native lap source of truth to handle lap undo.
- Additional languages.

---

## Open decisions for the owner

1. Bar metric: pace, distance or power (or user setting)?
2. Is T0 (fēnix 3 generation) frozen at the phase-1 feature set, or should each feature be attempted there when the budget allows?
3. Rounding vs. truncation of the last decimal (C7).
4. Is a Stryd + Garmin native power comparison a goal (requires option B) or is Stryd-only sufficient (option A)?
