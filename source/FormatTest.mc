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
