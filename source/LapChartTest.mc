using Toybox.Graphics as Gfx;
using Toybox.Test;

// Roadmap 4.1, 4.2 and 4.4: the lap bar chart. T1 and above only (the t1 annotation).

// A draw context that records the bars: [x, y, width, height, color] per fillRectangle.
(:test, :t1)
class RecordingDc {
  hidden var screenWidth;
  hidden var screenHeight;
  hidden var color = 0;
  var fills = [];

  function initialize(width, height) {
    screenWidth = width;
    screenHeight = height;
  }

  function getWidth() {
    return screenWidth;
  }

  function getHeight() {
    return screenHeight;
  }

  function setColor(foreground, background) {
    color = foreground;
  }

  function fillRectangle(x, y, width, height) {
    fills.add([x, y, width, height, color]);
  }
}

// Three finished laps (oldest first): 500 m in 150 s, 400 m in 100 s (fastest), 600 m in 240 s (slowest).
(:t1)
function historyWithThreeLaps() {
  var history = new LapHistory(10);
  history.add(500.0, 150000, null, null);
  history.add(400.0, 100000, null, null);
  history.add(600.0, 240000, null, null);
  return history;
}

(:test, :t1)
function testChartBarsAreOldestFirstAndEndWithTheCurrentLap(logger) {
  var model = new LapChartModel(8);
  model.update(historyWithThreeLaps(), 300.0);
  Test.assertEqualMessage(model.count, 4, "three finished laps and the lap in progress");
  Test.assertEqualMessage(model.fractionAt(0), 500.0 / 600.0, "the oldest lap first");
  Test.assertEqual(model.fractionAt(1), 400.0 / 600.0);
  Test.assertEqualMessage(model.fractionAt(2), 1.0, "the longest lap is the full height");
  Test.assertEqualMessage(model.fractionAt(3), 0.5, "the lap in progress grows");
  return true;
}

(:test, :t1)
function testChartScaleFollowsTheLongestBarInView(logger) {
  var model = new LapChartModel(8);
  model.update(historyWithThreeLaps(), 1200.0);
  Test.assertEqualMessage(model.fractionAt(3), 1.0, "a current lap longer than all others sets the scale");
  Test.assertEqual(model.fractionAt(2), 0.5);
  // the 600 m lap is no longer in view with 3 slots: 2 finished laps and the current one
  model = new LapChartModel(3);
  model.update(historyWithThreeLaps(), 300.0);
  Test.assertEqualMessage(model.count, 3, "no more bars than slots");
  Test.assertEqual(model.fractionAt(0), 400.0 / 600.0);
  Test.assertEqual(model.fractionAt(1), 1.0);
  return true;
}

(:test, :t1)
function testChartWithoutLapsShowsTheCurrentLapOnly(logger) {
  var model = new LapChartModel(8);
  model.update(new LapHistory(10), 250.0);
  Test.assertEqual(model.count, 1);
  Test.assertEqual(model.fractionAt(0), 1.0);
  model.update(new LapHistory(10), 0.0);
  Test.assertEqualMessage(model.fractionAt(0), 0.0, "nothing run yet");
  return true;
}

// Roadmap 4.2: colour by pace rank among the finished laps in view.
(:test, :t1)
function testChartRanksTheLapsByPace(logger) {
  var model = new LapChartModel(8);
  model.update(historyWithThreeLaps(), 300.0);
  Test.assertEqual(model.rankAt(0), LapChartModel.RANK_NONE);
  Test.assertEqualMessage(model.rankAt(1), LapChartModel.RANK_FASTEST, "400 m in 100 s");
  Test.assertEqualMessage(model.rankAt(2), LapChartModel.RANK_SLOWEST, "600 m in 240 s");
  Test.assertEqualMessage(model.rankAt(3), LapChartModel.RANK_NONE, "the lap in progress has no rank yet");
  return true;
}

(:test, :t1)
function testChartHasNoRankWithoutADifference(logger) {
  var history = new LapHistory(10);
  history.add(500.0, 150000, null, null);
  var model = new LapChartModel(8);
  model.update(history, 100.0);
  Test.assertEqualMessage(model.rankAt(0), LapChartModel.RANK_NONE, "one lap has no fastest or slowest");
  history.add(500.0, 150000, null, null);
  model.update(history, 100.0);
  Test.assertEqualMessage(model.rankAt(0), LapChartModel.RANK_NONE, "equal laps (a fixed auto lap) have no rank");
  Test.assertEqual(model.rankAt(1), LapChartModel.RANK_NONE);
  return true;
}

(:test, :t1)
function testChartIgnoresALapWithoutTimeForTheRank(logger) {
  var history = new LapHistory(10);
  history.add(500.0, 150000, null, null);
  history.add(300.0, 0, null, null);
  history.add(400.0, 80000, null, null);
  var model = new LapChartModel(8);
  model.update(history, 100.0);
  Test.assertEqual(model.rankAt(0), LapChartModel.RANK_SLOWEST);
  Test.assertEqualMessage(model.rankAt(1), LapChartModel.RANK_NONE, "no time: no pace");
  Test.assertEqual(model.rankAt(2), LapChartModel.RANK_FASTEST);
  return true;
}

// Roadmap 4.4: only where there is room.
(:test, :t1)
function testChartNeedsAFieldOfAMinimumSize(logger) {
  Test.assertMessage(LapChart.fits(240, 240), "a full screen");
  Test.assertMessage(LapChart.fits(200, 100), "a large half screen");
  Test.assertMessage(!LapChart.fits(120, 60), "a field of a four-field screen is too small");
  Test.assertMessage(!LapChart.fits(240, 80), "too low");
  Test.assertMessage(!LapChart.fits(100, 200), "too narrow");
  return true;
}

(:test, :t1)
function testChartDrawsOneBarPerLapRightAligned(logger) {
  LapLog.start();
  LapLog.history.add(500.0, 150000, null, null);
  LapLog.history.add(400.0, 100000, null, null);
  LapLog.history.add(600.0, 240000, null, null);
  var dc = new RecordingDc(200, 120);
  LapChart.draw(dc, Gfx.COLOR_BLACK, 300.0);
  Test.assertEqualMessage(dc.fills.size(), 4, "three laps and the lap in progress");
  var last = dc.fills[3];
  Test.assertMessage(last[0] + last[2] <= 200, "inside the field");
  Test.assertEqualMessage(last[1] + last[3], 120, "bars stand on the bottom edge");
  Test.assertMessage(dc.fills[2][3] > dc.fills[3][3], "the 600 m lap is taller than the 300 m current lap");
  Test.assertMessage(dc.fills[0][0] < dc.fills[1][0], "oldest on the left");
  Test.assertEqualMessage(dc.fills[1][4], Gfx.COLOR_GREEN, "the fastest lap on a black background");
  Test.assertEqualMessage(dc.fills[2][4], Gfx.COLOR_RED, "the slowest lap on a black background");
  LapLog.reset();
  return true;
}

(:test, :t1)
function testChartDrawsNothingInASmallField(logger) {
  LapLog.start();
  var dc = new RecordingDc(120, 60);
  LapChart.draw(dc, Gfx.COLOR_BLACK, 300.0);
  Test.assertEqual(dc.fills.size(), 0);
  return true;
}

(:test, :t1)
function testChartColorsFollowTheBackground(logger) {
  Test.assertMessage(
    LapChart.colorFor(LapChartModel.RANK_FASTEST, false, Gfx.COLOR_WHITE) != LapChart.colorFor(LapChartModel.RANK_FASTEST, false, Gfx.COLOR_BLACK),
    "a darker green on white"
  );
  Test.assertMessage(
    LapChart.colorFor(LapChartModel.RANK_NONE, true, Gfx.COLOR_BLACK) != LapChart.colorFor(LapChartModel.RANK_NONE, false, Gfx.COLOR_BLACK),
    "the lap in progress stands out from the finished laps"
  );
  return true;
}
