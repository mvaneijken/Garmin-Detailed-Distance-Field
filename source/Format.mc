// Pure formatting functions: no screen, no settings store, so unit tests can call them directly.
module Format {
  const POWERS_OF_TEN = [1, 10, 100, 1000];

  // distance: meters (Float). unitMeters: meters per kilometer or per mile.
  // The digits per band come from the settings (0 to 3 each): 0 to 1, 1 to 10, 10 to 100 and
  // 100+ km or miles.
  //
  // The last digit is truncated, not rounded: the field never shows a distance that has not been
  // covered (999.6 m shows 0.999, not 1.000). The small correction before the cut absorbs the
  // error of 32-bit floats, so that exactly 1000 m shows 1.000 and not 0.999.
  function distanceString(distance, unitMeters, settings) {
    var units = 0.0;
    if (distance > 0) {
      units = distance / unitMeters;
    }
    var digits = settings.hundredOnwardsDigits;
    if (units < 1) {
      digits = settings.zeroToOneDigits;
    } else if (units < 10) {
      digits = settings.oneToTenDigits;
    } else if (units < 100) {
      digits = settings.tenToHundredDigits;
    }
    var scale = POWERS_OF_TEN[digits];
    var scaled = (units * scale * 1.000001 + 0.0005).toNumber();
    if (digits == 0) {
      return scaled.toString();
    }
    var fraction = (scaled % scale).toString();
    while (fraction.length() < digits) {
      fraction = "0" + fraction;
    }
    return (scaled / scale).toString() + "." + fraction;
  }
}
