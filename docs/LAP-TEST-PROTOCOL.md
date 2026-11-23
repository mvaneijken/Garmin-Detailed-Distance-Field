# Manual lap test protocol (roadmap 0.5)

The lap behaviour of the field depends on events that only a real device (or a simulator with activity playback) produces. The open questions are findings C2 to C5 in `docs/ANALYSIS.md` section 3. Run this protocol once on the fēnix 9 Pro and once on an older device or simulator target, record the results below, and use them to decide the Phase 1 fixes (`onTimerReset`, lap-event de-duplication, multisport).

Nothing here needs a code change. Use the build of the current `master`.

## Setup

1. Install the field from a build of `master` (sideload the `.prg` of your device, or use the simulator).
2. Add the field to a data screen that also shows the native **Lap Distance** and **Last Lap Distance** fields, so each scenario can be compared with the native value.
3. Note device, firmware, field version and Connect IQ version in the results table.
4. After each scenario, check the lap table of the saved activity in Garmin Connect when possible. The FIT laps are the reference for lap distances.

What to read on screen: the large value is the current lap distance; the second line (`LL ...` / `LR ...`, if "show previous lap" is on) is the previous lap distance. Turn the second line on for every scenario.

## Scenarios

For each scenario write down the value shown by the field (F) and by the native fields (N) at the points marked **Record**.

| # | Finding | Scenario | Steps | Expected | Record |
|---|---|---|---|---|---|
| S1 | baseline | Manual lap | Start a run. After about 300 m press the lap button. Repeat after about 200 m. | Current lap restarts at 0. Previous lap equals the native last lap. | F and N previous lap after each press. |
| S2 | baseline | Auto lap | Turn on auto lap by distance (for example 0.5 km). Run past two boundaries. | Same as S1 without button presses. | F and N previous lap at each boundary. |
| S3 | C3 | Workout, distance step | Run a structured workout with a distance step (for example 400 m run, 200 m recovery). Complete two steps. | One new lap per step. Previous lap equals the step distance. | F previous lap after each step. Does it ever show about 0? |
| S4 | C3 | Workout, lap-button step | Run a workout with a step that ends on the lap button. Press the lap button to end it. | One new lap. Previous lap equals the distance run in the step. | F previous lap right after the press. If it shows about 0, both events fired (finding C3 confirmed). |
| S5 | C3 | Workout, final step | Finish the last step of a workout. | Previous lap shows the last step, or the field is unchanged if the event is not sent for the final step. | F and N values at the end; note whether the field updated. |
| S6 | C4 | Lap undo | Press lap, then undo the lap (if the watch offers it). | Native lap distance continues the earlier lap. The field is expected to diverge (open Garmin request). | F and N current lap after the undo, and how far they differ. |
| S7 | C2 | Save and start again | Run with at least two laps. Stop and save. Start a new activity of the same profile without leaving the data screen. | Current lap 0, previous lap empty. If old values appear, the instance survives and `onTimerReset` is needed. | F values within 10 s of starting. |
| S8 | C5 | Multisport | Use a triathlon or multisport profile. Switch leg (for example run to bike) with the multisport transition. | Current lap restarts at 0, never negative, and does not keep the distance of the previous leg. | F current and previous lap after the transition; note any negative value or a value as large as the previous leg. |

## Optional: simulator

The Connect IQ simulator can drive a data field with simulated activity data and timer events (see its Simulation menu; the menu names differ per SDK version, and this protocol does not rely on them). It is not expected to reproduce workout step events or lap undo, so S3 to S6 stay device tests. Use it for S1, S2, S7 and for the older device (for example fenix3 or fenix5), and write down in the Notes column which events you could trigger.

## Results

Copy one row per scenario and device. Result codes: `ok` (as expected), `diff` (differs, describe), `n/a` (not possible on this device).

| Date | Device | Firmware | CIQ | Field version | Scenario | Result | F | N | Notes |
|---|---|---|---|---|---|---|---|---|---|
| | fēnix 9 Pro 47 mm | | | | S1 | | | | |
| | fēnix 9 Pro 47 mm | | | | S2 | | | | |
| | fēnix 9 Pro 47 mm | | | | S3 | | | | |
| | fēnix 9 Pro 47 mm | | | | S4 | | | | |
| | fēnix 9 Pro 47 mm | | | | S5 | | | | |
| | fēnix 9 Pro 47 mm | | | | S6 | | | | |
| | fēnix 9 Pro 47 mm | | | | S7 | | | | |
| | fēnix 9 Pro 47 mm | | | | S8 | | | | |
| | older device or simulator | | | | S1 | | | | |
| | older device or simulator | | | | S2 | | | | |
| | older device or simulator | | | | S7 | | | | |

## How the results are used

| Result | Decision |
|---|---|
| S4 shows about 0 | Phase 1.4: de-duplicate lap events (one boundary, one lap). |
| S5 shows no update at the end | Document it; consider reading the lap distance at `onTimerStop` or on the next lap. |
| S7 shows old values | Phase 1.4: add `onTimerReset` to clear the lap state. |
| S8 shows a negative value (distance reset per leg) or a large leftover value (distance stays cumulative across legs) | Phase 1.4: handle the leg change explicitly (`onNextMultisportLeg`: restart the lap baseline) and clamp the lap distance to 0 or more. |
| S6 diverges | Phase 5: evaluate `Activity.SplitInfo` (API 5.2.2+). |
