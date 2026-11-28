using Toybox.Test;

// The spike lines are read by the owner (docs/STRYD-SPIKE.md), not by a script; the tests pin the format so a
// capture from two sessions can be compared. They exist in the spike build only (spike.jungle).

(:test, :spike)
class FakeRunningDynamics {
  var groundContactTime = 232;
  var verticalOscillation = 8.5;
  var stanceTime = null;
  var stepLength = 1120;
  var cadence = 176;
  var verticalRatio = null;
  var groundContactBalance = 50.5;
}

(:test, :spike)
class FakeManufacturer {
  var manufacturerId = 255;
  var modelNumber = null;
  var hwRevision = 3;
}

(:test, :spike)
function testSpikeRunningDynamicsLine(logger) {
  Test.assertEqualMessage(
    Spike.runningDynamicsLine(123456, new FakeRunningDynamics()),
    "S,rd,123456,232,8.500000,null,1120,176,null,50.500000",
    "ground contact time, vertical oscillation, stance time, step length, cadence, vertical ratio, balance"
  );
  return true;
}

(:test, :spike)
function testSpikeManufacturerLine(logger) {
  Test.assertEqualMessage(
    Spike.manufacturerLine(5000, "rd", new FakeManufacturer()),
    "S,mfr,5000,rd,255,null,3",
    "manufacturer, model, hardware revision of the sensor on a profile"
  );
  return true;
}

(:test, :spike)
function testSpikeTextOfANull(logger) {
  Test.assertEqual(Spike.text(null), "null");
  Test.assertEqual(Spike.text(5), "5");
  return true;
}
