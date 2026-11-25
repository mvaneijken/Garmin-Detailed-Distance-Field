using Toybox.Test;

// Unit tests (built only with the unit-test flag, see tools/ci/run-unit-tests.sh).
// These describe the behaviour of Format as it is today, including the rounding and the 1610 m mile;
// the correctness fixes of roadmap 1.4 change the expected values in the commit that fixes them.

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
  Test.assertEqualMessage(Format.distanceString(123456.0, 1000, settings), "123.46", "100 km and more");
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
  Test.assertEqualMessage(Format.distanceString(123456.0, 1000, settings), "123.5", "one digit, 100+");
  return true;
}

(:test)
function testFormatStatuteMile(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 3;
  settings.oneToTenDigits = 3;
  // The field uses 1610 m for a mile today; roadmap 1.4 (C1) changes it to 1609.344 m.
  Test.assertEqualMessage(Format.distanceString(1610.0, 1610, settings), "1.000", "one mile");
  Test.assertEqualMessage(Format.distanceString(805.0, 1610, settings), "0.500", "half a mile");
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

(:test)
function testFormatRoundsLastDecimal(logger) {
  var settings = new Settings();
  settings.zeroToOneDigits = 3;
  // Known finding C7: 999.6 m is shown as 1.000 although 1 km is not covered yet.
  // Roadmap 1.4 changes this to truncation (expected "0.999").
  Test.assertEqualMessage(Format.distanceString(999.6, 1000, settings), "1.000", "rounds up today");
  return true;
}
