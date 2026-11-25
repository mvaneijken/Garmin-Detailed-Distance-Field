// Lap bookkeeping, driven by plain numbers so unit tests can replay lap scenarios.
class LapTracker {
  // Last elapsed distance seen (meters). Stays unchanged when the device reports no distance.
  var distance = 0;
  // Elapsed distance at the start of the current lap.
  var lapStart = 0;
  var currentLap = 0;
  var previousLap = 0;
  // The timer time (milliseconds, Activity.Info.timerTime) works like the distance: the last value
  // seen, the value at the start of the lap, and the times of the current and the previous lap.
  var timer = 0;
  var lapTimeStart = 0;
  var currentLapTime = 0;
  var previousLapTime = 0;
  // The lap in progress: 1 for the first lap, one more at every lap event.
  var lapNumber = 1;

  function initialize() {}

  // elapsed is Activity.Info.timerTime in milliseconds: null while the device has no timer value.
  function onTimer(elapsed) {
    if (elapsed != null) {
      timer = elapsed;
      currentLapTime = timer - lapTimeStart;
    } else {
      currentLapTime = 0;
    }
  }

  // elapsed is Activity.Info.elapsedDistance: null while the device has no distance yet.
  function onDistance(elapsed) {
    if (elapsed != null) {
      distance = elapsed;
      currentLap = distance - lapStart;
    } else {
      currentLap = 0.0;
    }
  }

  // The activity was saved or discarded: start from scratch (finding C2).
  function reset() {
    distance = 0;
    lapStart = 0;
    currentLap = 0;
    previousLap = 0;
    timer = 0;
    lapTimeStart = 0;
    currentLapTime = 0;
    previousLapTime = 0;
    lapNumber = 1;
  }

  // A lap boundary: manual lap, auto lap or the end of a workout step. The two events run the
  // same code; whether both can fire for one boundary is roadmap item 0.5 (finding C3).
  function onLap() {
    previousLap = distance - lapStart;
    lapStart = distance;
    previousLapTime = timer - lapTimeStart;
    lapTimeStart = timer;
    lapNumber += 1;
  }
}
