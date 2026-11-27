using Toybox.Test;

// Roadmap 2.1: the lap history exists on T1 and above only (the t1 annotation), so its tests do too.

(:test, :t1)
function testHistoryStartsEmpty(logger) {
  var history = new LapHistory(3);
  Test.assertEqual(history.count, 0);
  Test.assertMessage(history.distanceAt(0) == null, "no lap yet");
  return true;
}

(:test, :t1)
function testHistoryKeepsTheNewestLapFirst(logger) {
  var history = new LapHistory(5);
  history.add(500.0, 150000, null);
  history.add(480.0, 140000, null);
  history.add(510.0, 160000, null);
  Test.assertEqual(history.count, 3);
  Test.assertEqualMessage(history.distanceAt(0), 510.0, "newest");
  Test.assertEqualMessage(history.distanceAt(1), 480.0, "one before");
  Test.assertEqualMessage(history.distanceAt(2), 500.0, "oldest");
  Test.assertEqual(history.durationAt(0), 160000);
  Test.assertMessage(history.distanceAt(3) == null, "beyond the oldest lap");
  Test.assertMessage(history.distanceAt(-1) == null, "negative age");
  return true;
}

(:test, :t1)
function testHistoryDropsTheOldestWhenFull(logger) {
  var history = new LapHistory(3);
  for (var lap = 1; lap <= 5; lap += 1) {
    history.add(lap * 100.0, lap * 1000 + 60000, null);
  }
  Test.assertEqualMessage(history.count, 3, "never more than the capacity");
  Test.assertEqual(history.distanceAt(0), 500.0);
  Test.assertEqual(history.distanceAt(1), 400.0);
  Test.assertEqual(history.distanceAt(2), 300.0);
  Test.assertMessage(history.distanceAt(3) == null, "laps 1 and 2 are gone");
  return true;
}

(:test, :t1)
function testHistoryStoresTheLapTrigger(logger) {
  var history = new LapHistory(3);
  history.add(400.0, 90000, 0);
  history.add(200.0, 60000, 2);
  history.add(400.0, 90000, null);
  Test.assertMessage(history.triggerAt(0) == null, "the watch did not say why");
  Test.assertEqual(history.triggerAt(1), 2);
  Test.assertEqual(history.triggerAt(2), 0);
  return true;
}

// Finding C3: when two events report one boundary, the second one is a lap without distance and time.
// The history leaves it out; the second line of the field still shows it until the device test 0.5.
(:test, :t1)
function testHistoryIgnoresAnEmptyLap(logger) {
  var history = new LapHistory(3);
  Test.assertMessage(history.add(400.0, 90000, null), "a normal lap is stored");
  Test.assertMessage(!history.add(0.0, 0, null), "a lap of no distance and no time is not");
  Test.assertMessage(!history.add(0.4, 300, null), "neither is one under 1 m and under 1 s");
  Test.assertEqual(history.count, 1);
  Test.assertMessage(history.add(0.0, 5000, null), "no distance but a time (indoor): stored");
  Test.assertMessage(history.add(5.0, 0, null), "a distance but no timer value: stored");
  Test.assertEqual(history.count, 3);
  return true;
}

(:test, :t1)
function testHistoryClear(logger) {
  var history = new LapHistory(3);
  history.add(400.0, 90000, null);
  history.clear();
  Test.assertEqual(history.count, 0);
  Test.assertMessage(history.distanceAt(0) == null, "empty after clear");
  history.add(300.0, 80000, null);
  Test.assertEqual(history.distanceAt(0), 300.0);
  return true;
}

// More memory, more laps: fenix3-class devices do not have the history at all.
(:test, :t1)
function testHistoryCapacityFollowsTheMemory(logger) {
  Test.assertEqual(LapLog.capacityFor(32768), 12);
  Test.assertEqual(LapLog.capacityFor(65536), 50);
  Test.assertEqual(LapLog.capacityFor(131072), 50);
  Test.assertEqual(LapLog.capacityFor(262144), 50);
  return true;
}

// Roadmap 2.2 (reworked): a data field cannot read the workout step (Activity.getCurrentWorkoutStep throws
// in a data field), so a finished lap stores why it was made instead: the lap trigger of onTimerLap2
// (API 5.2.2), a marker for onWorkoutStepComplete, or null when the watch does not say.
(:test, :t1)
function testLapLogStoresTheTriggerOfTheLap(logger) {
  LapLog.start();
  var lap = new LapTracker();
  lap.onDistance(400.0);
  lap.onTimer(90000);
  lap.onLap();
  LapLog.record(lap, 2);
  lap.onDistance(600.0);
  lap.onTimer(150000);
  lap.onLap();
  LapLog.record(lap, LapLog.TRIGGER_STEP_COMPLETE);
  lap.onDistance(800.0);
  lap.onTimer(200000);
  lap.onLap();
  LapLog.record(lap, null);
  Test.assertEqualMessage(LapLog.history.triggerAt(2), 2, "an automatic lap by distance");
  Test.assertEqualMessage(LapLog.history.triggerAt(1), LapLog.TRIGGER_STEP_COMPLETE, "the end of a workout step");
  Test.assertMessage(LapLog.history.triggerAt(0) == null, "an older watch does not say");
  LapLog.reset();
  return true;
}

// The log follows the lap tracker: one entry per lap event, none after a reset.
(:test, :t1)
function testLapLogFollowsTheTracker(logger) {
  LapLog.start();
  var lap = new LapTracker();
  lap.onDistance(500.0);
  lap.onTimer(150000);
  lap.onLap();
  LapLog.record(lap, null);
  lap.onDistance(980.0);
  lap.onTimer(290000);
  lap.onLap();
  LapLog.record(lap, null);
  Test.assertEqual(LapLog.history.count, 2);
  Test.assertEqual(LapLog.history.distanceAt(0), 480.0);
  Test.assertEqual(LapLog.history.durationAt(1), 150000);
  lap.reset();
  LapLog.reset();
  Test.assertEqualMessage(LapLog.history.count, 0, "a new activity starts with no laps");
  return true;
}
