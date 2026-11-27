using Toybox.Test;

// Settings.load() reads the property store; without synced user settings it returns the defaults
// of resources/properties/properties.xml.
(:test)
function testSettingsLoadDefaults(logger) {
  var settings = new Settings();
  settings.load();
  Test.assertEqual(settings.showLastLap, true);
  Test.assertEqual(settings.zeroToOneDigits, 3);
  Test.assertEqual(settings.oneToTenDigits, 3);
  Test.assertEqual(settings.tenToHundredDigits, 3);
  Test.assertEqual(settings.hundredOnwardsDigits, 2);
  Test.assertEqual(settings.hideLabel, false);
  Test.assertEqual(settings.overrideSizing, false);
  Test.assertEqual(settings.heightOversize, 100);
  Test.assertEqual(settings.widthOversize, 100);
  Test.assertEqualMessage(settings.secondLine, 0, "the second line shows the previous lap distance");
  return true;
}

// Finding C6: a missing or broken value must not reach the format string.
(:test)
function testSettingsClampKeepsValuesInRange(logger) {
  var settings = new Settings();
  Test.assertEqualMessage(settings.clamp(2, 0, 3, 3), 2, "in range");
  Test.assertEqualMessage(settings.clamp(0, 0, 3, 3), 0, "lower bound");
  Test.assertEqualMessage(settings.clamp(3, 0, 3, 3), 3, "upper bound");
  Test.assertEqualMessage(settings.clamp(7, 0, 3, 3), 3, "above the range");
  Test.assertEqualMessage(settings.clamp(-2, 0, 3, 3), 0, "below the range");
  Test.assertEqualMessage(settings.clamp(40, 50, 150, 100), 50, "below the percentage range");
  Test.assertEqualMessage(settings.clamp(500, 50, 150, 100), 150, "above the percentage range");
  return true;
}

(:test)
function testSettingsClampFallsBackWhenNotANumber(logger) {
  var settings = new Settings();
  Test.assertEqualMessage(settings.clamp(null, 0, 3, 2), 2, "null");
  Test.assertEqualMessage(settings.clamp("abc", 0, 3, 2), 2, "text");
  Test.assertEqualMessage(settings.clamp(true, 0, 3, 2), 2, "boolean");
  Test.assertEqualMessage(settings.clamp([1], 0, 3, 2), 2, "array");
  return true;
}

(:test)
function testSettingsLiveSecondLine(logger) {
  var settings = new Settings();
  settings.secondLine = 0;
  Test.assertMessage(!settings.isLiveSecondLine(), "previous lap distance changes at a lap only");
  settings.secondLine = 4;
  Test.assertMessage(!settings.isLiveSecondLine(), "the lap number too");
  settings.secondLine = 3;
  Test.assertMessage(settings.isLiveSecondLine(), "the current lap time changes every second");
  settings.secondLine = 5;
  Test.assertMessage(settings.isLiveSecondLine(), "so does power");
  settings.secondLine = 11;
  Test.assertMessage(settings.isLiveSecondLine(), "and pace");
  return true;
}

(:test)
function testSettingsClampConvertsNumbersInOtherTypes(logger) {
  var settings = new Settings();
  Test.assertEqualMessage(settings.clamp(2.9, 0, 3, 3), 2, "a float is cut to a whole number");
  Test.assertEqualMessage(settings.clamp("1", 0, 3, 3), 1, "a number in text");
  return true;
}
