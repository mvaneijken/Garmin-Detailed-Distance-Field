using Toybox.Activity;

// Reads the intensity of the current workout step (roadmap 2.2). Activity.getCurrentWorkoutStep() exists from
// Connect IQ 3.2.0; devices whose highest version is lower get the empty twin (the workoutinfo annotations
// come from the per-device lines in monkey.jungle). A device that has the API but runs an older firmware is
// covered by the `has` check. The value goes to LapLog (every device with the API is T1 or above, so LapLog
// keeps the real functions there).
module WorkoutIntensity {
  (:workoutinfo)
  function read() {
    if (Activity has :getCurrentWorkoutStep) {
      var step = Activity.getCurrentWorkoutStep();
      LapLog.setIntensity(step == null ? null : step.intensity);
    }
  }

  (:noworkoutinfo)
  function read() {}
}
