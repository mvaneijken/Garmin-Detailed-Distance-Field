using Toybox.Application as App;

// The user settings, read once and cached. The view reloads them in onSettingsChanged() and when the
// layout changes, instead of reading the property store six times per second.
class Settings {
  var showLastLap = false;
  var zeroToOneDigits = 3;
  var oneToTenDigits = 2;
  var tenToHundredDigits = 2;
  var hundredOnwardsDigits = 1;
  var hideLabel = false;
  var overrideSizing = false;
  var heightOversize = 100;
  var widthOversize = 100;

  function initialize() {}

  function load() {
    var showLastLapValue = readProperty("showLastLap_prop");
    if (null == showLastLapValue) {
      showLastLap = false;
    } else {
      showLastLap = showLastLapValue;
    }
    zeroToOneDigits = readProperty("zerotoone");
    oneToTenDigits = readProperty("onetoten");
    tenToHundredDigits = readProperty("tentohundred");
    hundredOnwardsDigits = readProperty("hundredonwards");
    hideLabel = readProperty("hideLabel");
    overrideSizing = readProperty("overridesizeing");
    heightOversize = readProperty("heightoversizeoverride");
    widthOversize = readProperty("widthoversizeoverride");
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
