// Lap bookkeeping, driven by plain numbers so unit tests can replay lap scenarios.
class LapTracker {
  // Last elapsed distance seen (meters). Stays unchanged when the device reports no distance.
  var distance = 0;
  // Elapsed distance at the start of the current lap.
  var lapStart = 0;
  var currentLap = 0;
  var previousLap = 0;

  function initialize() {}

  // elapsed is Activity.Info.elapsedDistance: null while the device has no distance yet.
  function onDistance(elapsed) {
    if (elapsed != null) {
      distance = elapsed;
      currentLap = distance - lapStart;
    } else {
      currentLap = 0.0;
    }
  }

  // A lap boundary: manual lap, auto lap or the end of a workout step. The two events run the
  // same code; whether both can fire for one boundary is roadmap item 0.5 (finding C3).
  function onLap() {
    previousLap = distance - lapStart;
    lapStart = distance;
  }
}
