# Power, cadence and pace in the field (roadmap 3.2, 3.3, 3.7)

Since the second-line setting grew, the field can show the values the watch reads from its sensors. A Stryd needs no special support for this: once the watch uses it as a power sensor (and as a foot pod for pace, distance and cadence), its values arrive through the standard Garmin activity data like those of any other sensor.

## What can be shown

Setting **Second line shows** (needs "Show second line" on):

| Setting value | Label | Content | Source |
|---|---|---|---|
| Previous lap distance, time, pace; current lap time; lap number | LL, LT, LP, CT, Lap | lap values | the field itself |
| Power | PWR | current power in watts | `Activity.Info.currentPower` |
| Power, last 3 / 10 / 30 seconds | P3s, P10s, P30s | rolling average of the last samples | the field (about one sample per second) |
| Average power of the lap | LapW | average since the lap started | the field |
| Cadence | CAD | steps or revolutions per minute | `Activity.Info.currentCadence` |
| Current pace | Pace | per kilometer or mile, like the main value | `Activity.Info.currentSpeed` |

Rules: a value the watch does not have shows `--` (or `--:--`); power of 0 W is a value (coasting) and counts in the averages; a missing power sample does not. The three power windows are averages over the last 3, 10 or 30 samples; after a lap button press the rolling windows continue, only the lap average starts again. Every finished lap also stores its average power in the lap history (T1 and above).

Not on fenix 3 (T0, 16 KB): its release build had no room for the sensor code (see `docs/MEMORY-BASELINE.md`). It shows `--` for these contents.

## Using a Stryd (to be confirmed on your watch)

- Pair the Stryd in the watch's sensor menu, as a power sensor, and also as a foot pod if you want its pace, distance and cadence. The exact menu names depend on the watch; check Stryd's own pairing guide for your model.
- For running power, check in the activity settings of the watch that the power data comes from the Stryd and not from the watch's own running power (a watch can hold both). The field shows what the watch reports as the activity's power.
- Offline sync, zones and workouts stay with Stryd: the field does not replace the **Stryd Zones** field's zone coloring, the sync of Stryd workouts to the watch, or PowerCenter. Form power, air power, leg spring stiffness, ground contact time and vertical oscillation are not shown: they are not part of the standard activity data (roadmap items 3.4 and 3.5 wait for the capture of what the Stryd broadcasts, item 3.1).

## What is verified

The values come from standard fields and are covered by unit tests with synthetic data (rolling windows, ring wrap, lap average, pace, `--` cases). Not verified on a watch with a real Stryd: that is for the owner (roadmap 3.1 is on the owner's hardware).
