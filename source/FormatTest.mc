using Toybox.Test;

// Unit tests (built only with the unit-test flag, see tools/ci/run-unit-tests.sh).

(:test)
function testFormatBands(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 3;
  settings.oneToTenDigits = 3;
  settings.tenToHundredDigits = 3;
  settings.hundredOnwardsDigits = 2;
  Test.assertEqualMessage(Format.distanceString(500.0, 1000, settings), "0.500", "below 1 km");
  Test.assertEqualMessage(Format.distanceString(1500.0, 1000, settings), "1.500", "1 to 10 km");
  Test.assertEqualMessage(Format.distanceString(12345.0, 1000, settings), "12.345", "10 to 100 km");
  Test.assertEqualMessage(Format.distanceString(123456.0, 1000, settings), "123.45", "100 km and more");
  return true;
}

(:test)
function testFormatDigitsPerBand(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 1;
  settings.oneToTenDigits = 2;
  settings.tenToHundredDigits = 0;
  settings.hundredOnwardsDigits = 1;
  Test.assertEqualMessage(Format.distanceString(500.0, 1000, settings), "0.5", "one digit");
  Test.assertEqualMessage(Format.distanceString(1500.0, 1000, settings), "1.50", "two digits");
  Test.assertEqualMessage(Format.distanceString(12345.0, 1000, settings), "12", "no digits");
  Test.assertEqualMessage(Format.distanceString(123456.0, 1000, settings), "123.4", "one digit, 100+");
  return true;
}

(:test)
function testFormatStatuteMile(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 3;
  settings.oneToTenDigits = 3;
  settings.tenToHundredDigits = 3;
  // Finding C1: a mile is 1609.344 m, not 1610 m (0.66 m per mile).
  var mile = Format.MILE_METERS;
  Test.assertEqualMessage(Format.distanceString(mile, mile, settings), "1.000", "one mile");
  Test.assertEqualMessage(Format.distanceString(804.672, mile, settings), "0.500", "half a mile");
  Test.assertEqualMessage(Format.distanceString(1609.0, mile, settings), "0.999", "1609 m is just short of a mile");
  Test.assertEqualMessage(Format.distanceString(1610.0, mile, settings), "1.000", "1610 m is past a mile");
  Test.assertEqualMessage(Format.distanceString(16093.44, mile, settings), "10.000", "ten miles");
  Test.assertEqualMessage(Format.distanceString(16093.0, mile, settings), "9.999", "just short of ten miles");
  return true;
}

(:test)
function testFormatZeroAndNegative(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 3;
  Test.assertEqualMessage(Format.distanceString(0, 1000, settings), "0.000", "zero, 3 digits");
  Test.assertEqualMessage(Format.distanceString(0.0, 1000, settings), "0.000", "zero float");
  Test.assertEqualMessage(Format.distanceString(-5.0, 1000, settings), "0.000", "negative");
  settings.zeroToOneDigits = 2;
  Test.assertEqualMessage(Format.distanceString(0, 1000, settings), "0.00", "zero, 2 digits");
  settings.zeroToOneDigits = 1;
  Test.assertEqualMessage(Format.distanceString(0, 1000, settings), "0.0", "zero, 1 digit");
  settings.zeroToOneDigits = 0;
  Test.assertEqualMessage(Format.distanceString(0, 1000, settings), "0", "zero, 0 digits");
  return true;
}

// Finding C7 (decision D3): the last decimal is truncated, never rounded up.
(:test)
function testFormatTruncatesTheLastDecimal(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 3;
  settings.oneToTenDigits = 3;
  settings.tenToHundredDigits = 3;
  settings.hundredOnwardsDigits = 2;
  Test.assertEqualMessage(Format.distanceString(999.0, 1000, settings), "0.999", "999 m");
  Test.assertEqualMessage(Format.distanceString(999.6, 1000, settings), "0.999", "999.6 m is not 1 km yet");
  Test.assertEqualMessage(Format.distanceString(1000.0, 1000, settings), "1.000", "exactly 1 km");
  Test.assertEqualMessage(Format.distanceString(1001.0, 1000, settings), "1.001", "1001 m");
  Test.assertEqualMessage(Format.distanceString(9999.0, 1000, settings), "9.999", "9999 m");
  Test.assertEqualMessage(Format.distanceString(9999.9, 1000, settings), "9.999", "9999.9 m");
  Test.assertEqualMessage(Format.distanceString(10000.0, 1000, settings), "10.000", "exactly 10 km");
  Test.assertEqualMessage(Format.distanceString(99999.0, 1000, settings), "99.999", "99999 m");
  Test.assertEqualMessage(Format.distanceString(100000.0, 1000, settings), "100.00", "exactly 100 km");
  return true;
}

// A distance just below the next step must not be promoted by the float correction.
(:test)
function testFormatDoesNotPromoteJustBelowABoundary(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 3;
  settings.oneToTenDigits = 3;
  settings.tenToHundredDigits = 3;
  Test.assertEqualMessage(Format.distanceString(999.999, 1000, settings), "0.999", "1 mm short of 1 km");
  // A 32-bit float cannot tell 1 mm from rounding error at 10 km (its resolution there is 1 mm).
  Test.assertEqualMessage(Format.distanceString(9999.99, 1000, settings), "9.999", "1 cm short of 10 km");
  Test.assertEqualMessage(Format.distanceString(1999.999, 1000, settings), "1.999", "1 mm short of 2 km");
  return true;
}

// The leading zeros of the fraction stay: 1.005 km is 1.005, not 1.5.
(:test)
function testFormatKeepsLeadingZerosOfTheFraction(logger) {
  var settings = new Settings();
  settings.oneToTenDigits = 3;
  settings.zeroToOneDigits = 3;
  Test.assertEqualMessage(Format.distanceString(1005.0, 1000, settings), "1.005", "1005 m");
  Test.assertEqualMessage(Format.distanceString(1050.0, 1000, settings), "1.050", "1050 m");
  Test.assertEqualMessage(Format.distanceString(7.0, 1000, settings), "0.007", "7 m");
  settings.oneToTenDigits = 2;
  Test.assertEqualMessage(Format.distanceString(1009.0, 1000, settings), "1.00", "two digits, 1009 m");
  return true;
}

// Roadmap 2.3: lap times and pace for the second line.
(:test)
function testFormatDuration(logger) {
  Test.assertEqualMessage(Format.durationString(0), "0:00", "zero");
  Test.assertEqualMessage(Format.durationString(999), "0:00", "under a second is cut, not rounded");
  Test.assertEqualMessage(Format.durationString(1000), "0:01", "one second");
  Test.assertEqualMessage(Format.durationString(59999), "0:59", "59.999 s");
  Test.assertEqualMessage(Format.durationString(60000), "1:00", "one minute");
  Test.assertEqualMessage(Format.durationString(3599999), "59:59", "just under an hour");
  Test.assertEqualMessage(Format.durationString(3600000), "1:00:00", "one hour");
  Test.assertEqualMessage(Format.durationString(3661000), "1:01:01", "1:01:01");
  Test.assertEqualMessage(Format.durationString(-5), "0:00", "negative");
  return true;
}

(:test)
function testFormatPace(logger) {
  var mile = Format.MILE_METERS;
  Test.assertEqualMessage(Format.paceString(1000.0, 300000, 1000), "5:00", "5:00 per km");
  Test.assertEqualMessage(Format.paceString(800.0, 240000, 1000), "5:00", "800 m in 4:00");
  Test.assertEqualMessage(Format.paceString(mile, 480000, mile), "8:00", "8:00 per mile");
  Test.assertEqualMessage(Format.paceString(1000.0, 299600, 1000), "5:00", "the pace is rounded to a second");
  Test.assertEqualMessage(Format.paceString(1000.0, 299400, 1000), "4:59", "299.4 s");
  Test.assertEqualMessage(Format.paceString(0.0, 60000, 1000), "--:--", "no distance");
  Test.assertEqualMessage(Format.paceString(1000.0, 0, 1000), "--:--", "no time");
  Test.assertEqualMessage(Format.paceString(1.0, 60000, 1000), "--:--", "slower than 99:59 per km");
  return true;
}

// The value of the second line follows the setting: 0 distance, 1 time, 2 pace of the previous lap,
// 3 time of the current lap, 4 number of the current lap.
(:test)
function testFormatSecondLineValue(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 3;
  var lap = new LapTracker();
  lap.onDistance(500.0);
  lap.onTimer(150000);
  lap.onLap();
  lap.onDistance(600.0);
  lap.onTimer(180000);
  settings.secondLine = 0;
  Test.assertEqualMessage(Format.secondLineValue(lap, 1000, settings), "0.500", "previous lap distance");
  settings.secondLine = 1;
  Test.assertEqualMessage(Format.secondLineValue(lap, 1000, settings), "2:30", "previous lap time");
  settings.secondLine = 2;
  Test.assertEqualMessage(Format.secondLineValue(lap, 1000, settings), "5:00", "previous lap pace");
  settings.secondLine = 3;
  Test.assertEqualMessage(Format.secondLineValue(lap, 1000, settings), "0:30", "current lap time");
  settings.secondLine = 4;
  Test.assertEqualMessage(Format.secondLineValue(lap, 1000, settings), "2", "current lap number");
  return true;
}
