# Stryd spike (roadmap 3.1): what does the sensor broadcast?

Goal (owner decision, Phase 3): show all Stryd metrics in this field, so the Stryd Zones field is no longer needed. Power, pace, cadence and distance come through the watch's standard activity data (roadmap 3.2, 3.3). The spike answers the open question for the rest: which of the other metrics (ground contact time, vertical oscillation, form power, air power, leg spring stiffness) does the Stryd actually broadcast, on which profile, and can a Connect IQ field receive them? The answer is the go/no-go for roadmap items 3.4 to 3.6.

It runs on the owner's hardware: a Stryd, the watch, and optionally an ANT+ USB stick and a phone. Two routes that complement each other.

## Route A: the spike build on the watch (about 15 minutes)

A build of the field that listens to two ANT+ profiles and logs what it hears (`source/Spike.mc`, built with `spike.jungle`; it needs the `Ant` permission, so it has its own manifest and is never part of a normal build).

1. Build it: `.\tools\probe\Build-LapProbe.ps1 -KeyPath <throwaway.der> -Devices fenix9pro47mm -Spike` (see `docs/LAP-TEST-PROTOCOL.md` for the throwaway key). The result is `tools\probe\out\fenix9pro47mm\LAPSPIKE.PRG`. Use a device with Connect IQ 2.4.0 or higher.
2. Copy it to `GARMIN/APPS`, create an empty `GARMIN/APPS/LOGS/LAPSPIKE.TXT`, add the field (name: Detailed Lap Distance) to a data screen, pair the Stryd to the watch as a power sensor and as a foot pod (the way you use it for a run), and start a run activity. Run for at least five minutes at a steady pace; then stop and save.
3. Read `LAPSPIKE.TXT` after the activity is saved. Lines:

| Line | Meaning |
|---|---|
| `S,tick,<clock>,rd,<state>/<ANT number>,power,<state>/<ANT number>` | every 10 s: the state of the Running Dynamics and the Bike Power profile and the ANT device number it found. A state of `0/0` all the time means: no sensor found on that profile. |
| `S,state,<clock>,<profile>,<state>/<ANT number>` | the profile changed state (searching, tracking, closed). |
| `S,mfr,<clock>,<profile>,<manufacturer id>,<model>,<hw revision>` | who the sensor says it is (manufacturer id 255 is a development id; Stryd has its own). |
| `S,rd,<clock>,<ground contact time ms>,<vertical oscillation>,<stance time>,<step length>,<cadence>,<vertical ratio>,<balance>` | one Running Dynamics update (at most once a second). `null` = the sensor did not send it. |
| `S,power,<clock>,<watts>,<power sensor type>` | one Bike Power update. |

4. Fill in the table below.

What this route cannot show: the proprietary Stryd pages (form power, air power, leg spring stiffness). A Connect IQ field is not expected to receive them; that is question 3 of route B. Untested on hardware (the simulator has no ANT): the spike builds, passes its unit tests for the line format and starts in the simulator, which prints the tick lines with state `0/0`.

## Route B: ANT+ and BLE capture tools (outside the repository)

For what only a capture can tell. Use an ANT+ USB stick with ANTware or SimulANT+ (or similar), and a phone with nRF Connect for Bluetooth. Record, with the Stryd awake and moving:

1. Which ANT+ device types does it open, with their channel period (power profile 11, foot pod profile 124, running dynamics 120?) and on which pages does it send data?
2. Which Bluetooth services and characteristics does it advertise (running power, running speed and cadence, and any custom service)?
3. Are the form power, air power and leg spring stiffness values in a page or a characteristic that has a public format? If they are only in a proprietary page, roadmap 3.5 is a no-go (and the owner's fallback stays: those metrics remain in Stryd PowerCenter after the offline sync).

Write the table of profiles, pages, data and update rates in the Results below. Check the terms of use of Stryd before decoding a proprietary page (roadmap 3.5 depends on that).

## Results

| Date | Watch | Stryd model/firmware | Route | Profile / page | Data seen | Update rate | Notes |
|---|---|---|---|---|---|---|---|
| | | | A | Running Dynamics | | | |
| | | | A | Bike Power | | | |
| | | | B | ANT+ pages | | | |
| | | | B | BLE services | | | |

## Decisions that follow

| Result | Decision |
|---|---|
| Running Dynamics updates with ground contact time and vertical oscillation arrive on the watch | Roadmap 3.4: show them through `AntPlus.RunningDynamics` (API 2.4.0, T1 and above). |
| Only power and pace arrive | Roadmap 3.4 and 3.5 are no-go; document that the other metrics stay in PowerCenter. |
| Form power, air power or leg spring stiffness are in a documented, decodable page | Roadmap 3.5: own `Ant.GenericChannel` decoder, after the terms check. |