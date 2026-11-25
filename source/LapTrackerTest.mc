using Toybox.Test;

// Lap scenarios of docs/LAP-TEST-PROTOCOL.md as event sequences. They describe what the field does
// with the events it receives; which events the firmware sends is a device question (roadmap 0.5).

(:test)
function testLapStartsAtZero(logger) {
  var lap = new LapTracker();
  lap.onDistance(0.0);
  Test.assertEqual(lap.currentLap, 0.0);
  Test.assertEqual(lap.previousLap, 0);
  return true;
}

// S1: manual lap
(:test)
function testManualLap(logger) {
  var lap = new LapTracker();
  lap.onDistance(300.0);
  Test.assertEqual(lap.currentLap, 300.0);
  lap.onLap();
  lap.onDistance(300.0);
  Test.assertEqualMessage(lap.currentLap, 0.0, "the current lap restarts at 0");
  Test.assertEqualMessage(lap.previousLap, 300.0, "the previous lap is the first lap");
  lap.onDistance(500.0);
  Test.assertEqual(lap.currentLap, 200.0);
  lap.onLap();
  Test.assertEqual(lap.previousLap, 200.0);
  return true;
}

// S2: auto lap at fixed boundaries
(:test)
function testAutoLapBoundaries(logger) {
  var lap = new LapTracker();
  var boundary = 500.0;
  for (var step = 1; step <= 4; step += 1) {
    lap.onDistance(boundary * step - 1.0);
    lap.onDistance(boundary * step);
    lap.onLap();
    Test.assertEqual(lap.previousLap, 500.0);
  }
  lap.onDistance(2100.0);
  Test.assertEqual(lap.currentLap, 100.0);
  return true;
}

// S3 and S5: a workout step that ends on distance, and the last step. Both use the same event.
(:test)
function testWorkoutStepComplete(logger) {
  var lap = new LapTracker();
  lap.onDistance(400.0);
  lap.onLap();
  lap.onDistance(600.0);
  lap.onLap();
  Test.assertEqual(lap.previousLap, 200.0);
  return true;
}

// S4 (finding C3): when the step end and the lap button both report the same boundary, the second
// event sets the previous lap to 0. This documents today's behaviour; the fix waits for device data.
(:test)
function testTwoEventsAtOneBoundaryZeroThePreviousLap(logger) {
  var lap = new LapTracker();
  lap.onDistance(400.0);
  lap.onLap();
  lap.onLap();
  Test.assertEqual(lap.previousLap, 0.0);
  return true;
}

// S7 (finding C2): save the activity and start a new one. The laps of the old activity must not
// show up in the new one.
(:test)
function testResetClearsTheLaps(logger) {
  var lap = new LapTracker();
  lap.onDistance(500.0);
  lap.onLap();
  lap.onDistance(800.0);
  lap.reset();
  Test.assertEqual(lap.currentLap, 0);
  Test.assertEqual(lap.previousLap, 0);
  lap.onDistance(0.0);
  Test.assertEqualMessage(lap.currentLap, 0.0, "the new activity starts at 0");
  lap.onDistance(120.0);
  Test.assertEqualMessage(lap.currentLap, 120.0, "and counts from its own start, not from 500 m");
  lap.onLap();
  Test.assertEqual(lap.previousLap, 120.0);
  return true;
}

// The device has no distance yet (indoor, no GPS): the lap shows 0 and keeps the last known distance.
(:test)
function testNoDistance(logger) {
  var lap = new LapTracker();
  lap.onDistance(250.0);
  lap.onDistance(null);
  Test.assertEqual(lap.currentLap, 0.0);
  Test.assertEqual(lap.distance, 250.0);
  lap.onDistance(260.0);
  Test.assertEqual(lap.currentLap, 260.0);
  return true;
}
