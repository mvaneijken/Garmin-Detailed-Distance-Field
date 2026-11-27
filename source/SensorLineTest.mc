using Toybox.Test;

// Roadmap 3.2 and 3.3: power, cadence and pace on the second line. T1 and above only (the t1 annotation);
// T0 devices show "--" for these contents.

(:test, :t1)
function testSensorLinePaceFromSpeed(logger) {
  var mile = Format.MILE_METERS;
  Test.assertEqualMessage(SensorLine.speedPaceString(1000.0 / 300.0, 1000), "5:00", "3.33 m/s is 5:00 per km");
  Test.assertEqualMessage(SensorLine.speedPaceString(3.0, mile), "8:56", "3 m/s is 8:56 per mile");
  Test.assertEqualMessage(SensorLine.speedPaceString(0.0, 1000), "--:--", "standing still");
  Test.assertEqualMessage(SensorLine.speedPaceString(0.1, 1000), "--:--", "slower than 99:59 per km");
  Test.assertEqualMessage(SensorLine.speedPaceString(null, 1000), "--:--", "no speed");
  return true;
}

(:test, :t1)
function testSensorLineCurrentValues(logger) {
  LapLog.start();
  SensorLine.setSample(null, null, null);
  Test.assertEqualMessage(SensorLine.value(5, 1000), "--", "no power meter");
  SensorLine.setSample(245, 172, 1000.0 / 300.0);
  Test.assertEqualMessage(SensorLine.value(5, 1000), "245", "current power");
  Test.assertEqualMessage(SensorLine.value(10, 1000), "172", "cadence");
  Test.assertEqualMessage(SensorLine.value(11, 1000), "5:00", "pace");
  SensorLine.setSample(null, null, null);
  Test.assertEqualMessage(SensorLine.value(10, 1000), "--", "no cadence");
  Test.assertEqualMessage(SensorLine.value(11, 1000), "--:--", "no speed");
  Test.assertEqualMessage(SensorLine.value(6, 1000), "--", "no power sample yet");
  Test.assertEqualMessage(SensorLine.value(9, 1000), "--", "no lap sample yet");
  return true;
}

(:test, :t1)
function testSensorLinePowerAverages(logger) {
  LapLog.start();
  for (var second = 1; second <= 30; second += 1) {
    LapLog.onPower(second <= 20 ? 200 : 300);
  }
  Test.assertEqualMessage(SensorLine.value(6, 1000), "300", "3 s power");
  Test.assertEqualMessage(SensorLine.value(7, 1000), "300", "10 s power");
  Test.assertEqualMessage(SensorLine.value(8, 1000), "233", "30 s power: 233.3");
  Test.assertEqualMessage(SensorLine.value(9, 1000), "233", "lap average power");
  LapLog.reset();
  return true;
}

// Format hands the contents from 5 on to the sensor line.
(:test, :t1)
function testFormatSecondLineUsesTheSensorLine(logger) {
  var settings = new Settings();
  var lap = new LapTracker();
  LapLog.start();
  SensorLine.setSample(245, 172, 3.0);
  settings.secondLine = 5;
  Test.assertEqualMessage(Format.secondLineValue(lap, 1000, settings), "245", "power");
  settings.secondLine = 10;
  Test.assertEqualMessage(Format.secondLineValue(lap, 1000, settings), "172", "cadence");
  SensorLine.setSample(null, null, null);
  return true;
}

// Every content has a label, and the label list matches the setting values.
(:test, :t1)
function testSensorLineLabels(logger) {
  Test.assertEqual(SensorLine.labelId(0), Rez.Strings.lastlaplabel);
  Test.assertEqual(SensorLine.labelId(4), Rez.Strings.lapnumberlabel);
  Test.assertEqual(SensorLine.labelId(5), Rez.Strings.powerlabel);
  Test.assertEqual(SensorLine.labelId(9), Rez.Strings.lappowerlabel);
  Test.assertEqual(SensorLine.labelId(11), Rez.Strings.pacelabel);
  return true;
}
