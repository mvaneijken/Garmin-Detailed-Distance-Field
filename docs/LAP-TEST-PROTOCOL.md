# Manual lap test protocol (roadmap 0.5)

The lap behaviour of the field depends on events that only a real device (or a simulator with activity playback) produces. The open questions are findings C2 to C5 in `docs/ANALYSIS.md` section 3. Run this protocol once on the fēnix 9 Pro and once on an older device or simulator target, record the results below, and use them to decide the Phase 1 fixes (`onTimerReset`, lap-event de-duplication, multisport).

Use the **probe build** (next section): the same code as `master` plus a short log line for every timer event. Nothing else changes in the field.

## Setup

1. Build the probe for your device with `tools/probe/Build-LapProbe.ps1` (see the run sheet below) and sideload the `LAPPROBE.PRG` of your device, or use the simulator.
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

## Automation: what can and cannot be scripted

The scenarios test two different things, and only one of them can run without a person and a watch.

| Layer | Question | Automatable | How |
|---|---|---|---|
| 1. Lap logic | Given a sequence of events and distances, does the field show the expected current and previous lap (S1 to S8, "Expected" column)? | Yes, in CI. | After Phase 1.1 the lap state lives in `LapTracker`, which takes plain numbers and events. Each scenario becomes a `(:test)` function that feeds an event sequence (for example S4: step end, then the lap button at the same distance) and asserts the values. The SDK runs them by building with the unit-test flag and starting the simulator, then `monkeydo <prg> <device> -t` (the form `tools/ci/run-unit-tests.sh` uses; the Windows page of the SDK documentation, Core Topics, "Unit Testing", writes the flag as `/t`); CI runs them under `xvfb` (roadmap 1.3). |
| 2. Firmware behaviour | Which events does the watch actually send in each scenario (findings C3, C4, C5), and with which distances? | No. Device only. | See below. |

Why layer 2 cannot be scripted (evidence level: forum reports, not Garmin documentation):

- The simulator cannot be driven from a script. Forum replies on automating it say it is not possible; the only reported route is OS-level key presses, which they call unreliable. The SDK contains an undocumented `shell` tool that I did not examine.
- FIT playback is only a data source. It does not replay timer events or workout steps; lap events in the simulator come from its menu.
- Reports exist that `onTimerLap` behaves differently on a real watch when a workout is loaded. That is exactly finding C3, so only a device can answer it.

What can be made cheap on the device: a probe build plus a log and a FIT comparison, so nobody has to write values down by hand.

All three parts are written: `source/Probe.mc` with `probe.jungle`, `tools/probe/Build-LapProbe.ps1` and `tools/probe/compare_lap_probe.py`; the run sheet follows below.

1. **Probe build** (a build flavour, never released): every callback (`onTimerStart`, `onTimerLap`, `onTimerStop`, `onTimerReset`, `onWorkoutStepComplete`, `onNextMultisportLeg`) prints one short line: `timerTime,event,elapsedDistance,currentLap,previousLap`. Print on events only, never on every `compute` or distance change: the lap distance changes continuously and would fill the small log within a minute. The values after an event are read by printing one extra line at the first `compute` after it.
2. **Device log**: sideload the probe `.prg`, create an empty `GARMIN/APPS/LOGS/<PRG name>.TXT` on the watch, run one scenario per activity, then read the file. Limits from the Connect IQ developer FAQ (community wiki, not verified on the fēnix 9 Pro): the file is not created automatically, it rolls over to a `.BAK` file after about 5 KB, and heavy printing slows the watch. Keep lines short and print only on events.
3. **Comparison**: a script reads the log and the lap table of the saved activity (the FIT file, parsed with a FIT tool such as the FIT SDK's `FitCSVTool`) and prints, per lap, the native lap distance next to the value the field showed. Its output is the Results table below. The script flags `DOUBLE EVENT` (two lap events within 2 s), `PREVIOUS = 0`, `DIFF > 5 m` and `NEGATIVE`, and ends with a one-line verdict for finding C3.

Still manual, about 15 minutes per device: doing the activity (the runs, the lap button presses, the workout, the multisport switch).

## Run sheet (probe build)

### One-time preparation

1. Make a throwaway developer key (a sideload does not need the store key):
   `openssl genrsa -out key.pem 4096` and `openssl pkcs8 -topk8 -inform PEM -outform DER -in key.pem -out throwaway.der -nocrypt`.
2. Build: `.\tools\probe\Build-LapProbe.ps1 -KeyPath <throwaway.der> -Devices fenix9pro47mm, fenix3`. The result is `tools\probe\out\<device>\LAPPROBE.PRG`. The file name is fixed on purpose: it names the log.
3. Python tools (once): `python -m venv tools\probe\.venv`, then `tools\probe\.venv\Scripts\pip install -r tools\probe\requirements.txt`.
4. Watch: connect it by USB, copy `LAPPROBE.PRG` to `GARMIN/APPS`, and create an empty file `GARMIN/APPS/LOGS/LAPPROBE.TXT`. The watch does not create the log file itself. Add the probe field (name: Detailed Lap Distance) to a data screen next to the native **Lap Distance** and **Last Lap Distance** fields, with the second line on.

### One scenario, one activity

Run each scenario as its own activity and keep it short (the log holds about 100 lines; it rolls over to `LAPPROBE.BAK` after about 5 KB). Save the activity at the end (this also tests S7's `onTimerReset`). After the run:

1. Connect the watch by USB (read the log after the activity is stopped and saved: it may be written late). Copy `GARMIN/APPS/LOGS/LAPPROBE.TXT` (and `LAPPROBE.BAK` if it exists) and the newest file of `GARMIN/Activity` (`.fit`). Empty the log file again before the next scenario (delete its content, keep the file).
2. Run the script: `tools\probe\.venv\Scripts\python tools\probe\compare_lap_probe.py --log LAPPROBE.BAK --log LAPPROBE.TXT --fit <activity>.fit` (leave `--log LAPPROBE.BAK` out when there is no `.BAK`). Keep the `.fit` file private (it holds a GPS track); the log is safe to share.
3. Paste the table into the Results below, with the verdict line. A log with more than one activity (S7) is cut after every reset: the script prints one table per activity, pairs the FIT file with the last activity that has laps (`--activity N` picks another one), and ends with a `Reset n: OK` or `OLD VALUES` line, which is the answer for finding C2.

### What to press, per scenario

| # | Presses |
|---|---|
| S1 | Start. Run about 300 m. Press lap. Run about 200 m. Press lap. Run 100 m. Stop and save. |
| S2 | Set auto lap to 0.5 km first. Start and run past two boundaries (1.2 km). Stop and save. |
| S3 | Run a workout with two distance steps (400 m, 200 m) and a third step. Let two steps end by themselves. Stop and save. |
| S4 | Run a workout whose first step ends on the lap button. Run 200 m, press lap. Run a distance step. Stop and save. |
| S5 | Run a short workout and let the **last** step finish. Wait 10 s. Stop and save. |
| S6 | Start, run 200 m, press lap, run 100 m, undo the lap (if the watch offers it), run 100 m. Stop and save. |
| S7 | Run 300 m with two laps, stop and save, then start a new activity of the same profile without leaving the data screen and wait 15 s. |
| S8 | Start a triathlon or multisport profile, run 200 m, switch leg (transition), go 200 m. Stop and save. |

The simulator (S1, S2 and S7 on fenix3): run `monkeydo tools\probe\out\fenix3\LAPPROBE.PRG fenix3` with the console captured to a file, press the lap and timer commands of its Simulation menu, and give that file to `--log`. There is no FIT file; the table then has an empty native column.

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
