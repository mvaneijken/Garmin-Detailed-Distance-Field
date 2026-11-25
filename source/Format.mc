// Pure formatting functions: no screen, no settings store, so unit tests can call them directly.
module Format {
  const ZERO_DISTANCE3 = "0.000";
  const ZERO_DISTANCE2 = "0.00";
  const ZERO_DISTANCE1 = "0.0";
  const ZERO_DISTANCE = "0";

  // distance: meters (Float). unitMeters: meters per kilometer or per mile.
  // The digits per band come from the settings: 0 to 1, 1 to 10, 10 to 100 and 100+ km or miles.
  function distanceString(distance, unitMeters, settings) {
    var distStr;
    if (distance > 0) {
      var distanceInUnits = distance / unitMeters;
      if (distanceInUnits < 1) {
        distStr = distanceInUnits.format("%." + settings.zeroToOneDigits + "f");
      } else if (distanceInUnits < 10) {
        distStr = distanceInUnits.format("%." + settings.oneToTenDigits + "f");
      } else if (distanceInUnits < 100) {
        distStr = distanceInUnits.format("%." + settings.tenToHundredDigits + "f");
      } else {
        distStr = distanceInUnits.format("%." + settings.hundredOnwardsDigits + "f");
      }
    } else {
      if (settings.zeroToOneDigits == 3) {
        distStr = ZERO_DISTANCE3;
      } else if (settings.zeroToOneDigits == 2) {
        distStr = ZERO_DISTANCE2;
      } else if (settings.zeroToOneDigits == 1) {
        distStr = ZERO_DISTANCE1;
      } else {
        distStr = ZERO_DISTANCE;
      }
    }
    return distStr;
  }
}
