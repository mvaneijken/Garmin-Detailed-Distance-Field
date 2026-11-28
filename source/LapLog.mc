using Toybox.System as Sys;

// The view's entry to the lap history (roadmap 2.1). Devices of tier T1 and above keep the history;
// T0 devices (the 16 KB data field memory) get empty twins, so the view calls it without caring.
// The tier annotations come from the per-device lines in monkey.jungle.
module LapLog {
  // Laps kept: more on devices with more memory. The memory limit of the app decides at run time, so a
  // new device needs no change here.
  (:t1)
  function capacityFor(totalMemory) {
    return totalMemory >= 65536 ? 50 : 12;
  }

  (:t1)
  var history = null;

  // The trigger stored for a lap that ended with onWorkoutStepComplete: the lap-trigger values of the watch
  // (DataField.LAP_TRIGGER_*, 0 to 24) cover why a lap was made, but this event has none of its own.
  const TRIGGER_STEP_COMPLETE = 100;

  // Rolling and lap average power (roadmap 3.2).
  (:t1)
  var power = null;

  (:t1)
  function start() {
    history = new LapHistory(capacityFor(Sys.getSystemStats().totalMemory));
    power = new PowerStats();
  }

  // Called every compute with Activity.Info.currentPower (null without a power meter).
  (:t1)
  function onPower(watts) {
    if (watts != null) {
      power.add(watts);
    }
  }

  // Average power of the newest seconds (3, 10 or 30), or null.
  (:t1)
  function averagePower(seconds) {
    return power.average(seconds);
  }

  (:t1)
  function lapAveragePower() {
    return power.lapAverage();
  }

  // Call after the tracker handled a lap event: its previous lap is the lap that just finished. trigger is
  // why the lap was made: a DataField.LAP_TRIGGER_* value (devices with API 5.2.2, onTimerLap2),
  // TRIGGER_STEP_COMPLETE, or null when the watch does not say (roadmap 2.2).
  (:t1)
  function record(lap, trigger) {
    history.add(lap.previousLap, lap.previousLapTime, trigger, power.lapAverage());
    power.onLap();
  }

  (:t1)
  function reset() {
    history.clear();
    power.clear();
  }

  (:t0)
  function start() {}

  (:t0)
  function record(lap, trigger) {}

  (:t0)
  function reset() {}
}
