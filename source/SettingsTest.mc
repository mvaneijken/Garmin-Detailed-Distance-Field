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
  return true;
}
