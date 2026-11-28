using Toybox.Test;

// Roadmap 3.2: rolling and lap average power. T1 and above only (the t1 annotation).

(:test, :t1)
function testPowerStatsWithoutSamples(logger) {
  var stats = new PowerStats();
  Test.assertMessage(stats.average(3) == null, "no sample, no average");
  Test.assertMessage(stats.lapAverage() == null, "no sample in the lap");
  return true;
}

(:test, :t1)
function testPowerStatsRollingAverage(logger) {
  var stats = new PowerStats();
  stats.add(100);
  stats.add(200);
  stats.add(300);
  Test.assertEqualMessage(stats.average(3), 200, "the last three");
  Test.assertEqualMessage(stats.average(2), 250, "the last two");
  Test.assertEqualMessage(stats.average(1), 300, "the last one");
  Test.assertEqualMessage(stats.average(10), 200, "fewer samples than the window: the ones there are");
  return true;
}

(:test, :t1)
function testPowerStatsRoundsToWholeWatts(logger) {
  var stats = new PowerStats();
  stats.add(1);
  stats.add(2);
  Test.assertEqual(stats.average(2), 2);
  stats.add(0);
  stats.add(0);
  stats.add(1);
  Test.assertEqualMessage(stats.average(3), 0, "0.33 W rounds to 0");
  return true;
}

// The ring holds 30 samples: older ones drop out of every window.
(:test, :t1)
function testPowerStatsRingWraps(logger) {
  var stats = new PowerStats();
  for (var second = 1; second <= 40; second += 1) {
    stats.add(second);
  }
  Test.assertEqual(stats.average(1), 40);
  Test.assertEqualMessage(stats.average(10), 36, "31 to 40: 35.5 rounds to 36");
  Test.assertEqualMessage(stats.average(30), 26, "11 to 40: 25.5 rounds to 26");
  Test.assertEqualMessage(stats.average(60), 26, "a window above 30 seconds is the whole ring");
  return true;
}

(:test, :t1)
function testPowerStatsLapAverage(logger) {
  var stats = new PowerStats();
  stats.add(100);
  stats.add(200);
  Test.assertEqual(stats.lapAverage(), 150);
  stats.onLap();
  Test.assertMessage(stats.lapAverage() == null, "a new lap starts without samples");
  stats.add(300);
  Test.assertEqual(stats.lapAverage(), 300);
  Test.assertEqualMessage(stats.average(3), 200, "the rolling window does not reset at a lap");
  return true;
}

(:test, :t1)
function testPowerStatsClear(logger) {
  var stats = new PowerStats();
  stats.add(100);
  stats.clear();
  Test.assertMessage(stats.average(3) == null, "empty after clear");
  Test.assertMessage(stats.lapAverage() == null, "no lap average after clear");
  return true;
}

// LapLog feeds the stats and stores the lap average with each finished lap.
(:test, :t1)
function testLapLogKeepsThePowerOfEachLap(logger) {
  LapLog.start();
  var lap = new LapTracker();
  LapLog.onPower(200);
  LapLog.onPower(220);
  LapLog.onPower(null);
  Test.assertEqualMessage(LapLog.lapAveragePower(), 210, "a missing sample is skipped");
  lap.onDistance(400.0);
  lap.onTimer(90000);
  lap.onLap();
  LapLog.record(lap, null);
  Test.assertEqual(LapLog.history.powerAt(0), 210);
  Test.assertMessage(LapLog.lapAveragePower() == null, "the next lap starts empty");
  LapLog.onPower(300);
  Test.assertEqual(LapLog.averagePower(3), 240);
  LapLog.reset();
  Test.assertMessage(LapLog.averagePower(3) == null, "a new activity forgets the old power");
  return true;
}
