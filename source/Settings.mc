using Toybox.Application as App;

// The user settings, read once and cached. The view reloads them in onSettingsChanged() instead of
// reading the property store six times per second. A missing or invalid value falls back to the
// default of resources/properties/properties.xml (finding C6: "%.nullf" is not a format).
class Settings {
  var showLastLap = false;
  // What the second line shows: 0 previous lap distance, 1 previous lap time, 2 previous lap pace,
  // 3 current lap time, 4 current lap number.
  var secondLine = 0;
  var zeroToOneDigits = 3;
  var oneToTenDigits = 3;
  var tenToHundredDigits = 3;
  var hundredOnwardsDigits = 2;
  var hideLabel = false;
  var overrideSizing = false;
  var heightOversize = 100;
  var widthOversize = 100;

  function initialize() {}

  function load() {
    showLastLap = readProperty("showLastLap_prop") == true;
    secondLine = clamp(readProperty("secondline"), 0, 4, 0);
    zeroToOneDigits = clamp(readProperty("zerotoone"), 0, 3, 3);
    oneToTenDigits = clamp(readProperty("onetoten"), 0, 3, 3);
    tenToHundredDigits = clamp(readProperty("tentohundred"), 0, 3, 3);
    hundredOnwardsDigits = clamp(readProperty("hundredonwards"), 0, 3, 2);
    hideLabel = readProperty("hideLabel") == true;
    overrideSizing = readProperty("overridesizeing") == true;
    heightOversize = clamp(readProperty("heightoversizeoverride"), 50, 150, 100);
    widthOversize = clamp(readProperty("widthoversizeoverride"), 50, 150, 100);
  }

  // value as a whole number between low and high; the fallback when it is missing or not a number.
  function clamp(value, low, high, fallback) {
    if (value == null || !(value has :toNumber)) {
      return fallback;
    }
    var number = value.toNumber();
    if (number == null) {
      return fallback;
    }
    if (number < low) {
      return low;
    }
    if (number > high) {
      return high;
    }
    return number;
  }

  // Application.Properties exists from Connect IQ 2.4.0; older devices use the AppBase method.
  function readProperty(propertyName) {
    if (App.Properties has :getValue) {
      return App.Properties.getValue(propertyName);
    } else {
      return App.getApp().getProperty(propertyName);
    }
  }
}
