using Toybox.Test;

// The probe line is the interface to tools/probe/compare_lap_probe.py. These tests exist only in a build with
// both the unit-test flag and probe.jungle (tools/ci/run-unit-tests.sh runs that second pass).
(:test, :probe)
function testProbeLineFormat(logger) {
  var lap = new LapTracker();
  lap.onDistance(500.0);
  lap.onTimer(95000);
  lap.onLap();
  lap.onDistance(510.5);
  lap.onTimer(96000);
  // Monkey C prints a float with six decimals; the script reads that.
  Test.assertEqualMessage(
    Probe.line("P", "lap", 123456, lap),
    "P,lap,123456,96000,510.500000,10.500000,500.000000,2",
    "the line the script parses"
  );
  return true;
}

(:test, :probe)
function testProbeLogsTheValueAfterAnEvent(logger) {
  var lap = new LapTracker();
  Probe.pending = false;
  Probe.event("lap", lap);
  Test.assertMessage(Probe.pending, "an event arms the line after the next compute");
  Probe.afterCompute(lap);
  Test.assertMessage(!Probe.pending, "one line per event, not one per compute");
  return true;
}
