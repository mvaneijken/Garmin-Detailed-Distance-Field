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

  // The workout intensity (Activity.WORKOUT_INTENSITY_*) of the step running at the last compute: null
  // outside a workout and on devices without the workout API (roadmap 2.2). A lap that ends takes it,
  // because the watch may already show the next step when the lap event arrives.
  (:t1)
  var intensity = null;

  (:t1)
  function start() {
    history = new LapHistory(capacityFor(Sys.getSystemStats().totalMemory));
  }

  (:t1)
  function setIntensity(value) {
    intensity = value;
  }

  // Call after the tracker handled a lap event: its previous lap is the lap that just finished.
  (:t1)
  function record(lap) {
    history.add(lap.previousLap, lap.previousLapTime, intensity);
  }

  (:t1)
  function reset() {
    history.clear();
    intensity = null;
  }

  (:t0)
  function setIntensity(value) {}

  (:t0)
  function start() {}

  (:t0)
  function record(lap) {}

  (:t0)
  function reset() {}
}
