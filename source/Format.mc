// Pure formatting functions: no screen, no settings store, so unit tests can call them directly.
module Format {
  const POWERS_OF_TEN = [1, 10, 100, 1000];
  // The international mile: exactly 1609.344 m.
  const MILE_METERS = 1609.344;

  // distance: meters (Float). unitMeters: meters per kilometer or per mile.
  // The digits per band come from the settings (0 to 3 each): 0 to 1, 1 to 10, 10 to 100 and
  // 100+ km or miles.
  //
  // The last digit is truncated, not rounded: the field never shows a distance that has not been
  // covered (999.6 m shows 0.999, not 1.000). The correction before the cut (0.00003 %, a few
  // units in the last place of a 32-bit float) only absorbs the rounding error of the division and
  // the multiplication, so that exactly 1000 m shows 1.000 and not 0.999. It is 0.3 mm at 1 km and
  // 3 mm at 10 km, which is about the resolution of the 32-bit distance itself: a distance 1 mm
  // short of 1 km still shows 0.999.
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
    var scaled = (units * scale * 1.0000003).toNumber();
    if (digits == 0) {
      return scaled.toString();
    }
    var fraction = (scaled % scale).toString();
    while (fraction.length() < digits) {
      fraction = "0" + fraction;
    }
    return (scaled / scale).toString() + "." + fraction;
  }

  // The value of the second line for the content chosen in the settings (settings.secondLine).
  function secondLineValue(lap, unitMeters, settings) {
    var content = settings.secondLine;
    if (content == 1) {
      return durationString(lap.previousLapTime);
    } else if (content == 2) {
      return paceString(lap.previousLap, lap.previousLapTime, unitMeters);
    } else if (content == 3) {
      return durationString(lap.currentLapTime);
    } else if (content == 4) {
      return lap.lapNumber.toString();
    }
    return distanceString(lap.previousLap, unitMeters, settings);
  }

  // milliseconds as m:ss, or h:mm:ss from one hour. Whole seconds, cut like the distance: a lap of
  // 59.9 s shows 0:59.
  function durationString(milliseconds) {
    var seconds = 0;
    if (milliseconds > 0) {
      seconds = (milliseconds / 1000).toNumber();
    }
    return clockString(seconds);
  }

  // Seconds per kilometer or mile as m:ss, rounded to a second like the pace of the watch itself.
  // "--:--" while there is no distance or no time, and for a pace slower than 99:59.
  function paceString(meters, milliseconds, unitMeters) {
    if (meters <= 0 || milliseconds <= 0) {
      return "--:--";
    }
    var seconds = (milliseconds / 1000.0) * unitMeters / meters;
    if (seconds >= 5999.5) {
      return "--:--";
    }
    return clockString((seconds + 0.5).toNumber());
  }

  function clockString(totalSeconds) {
    var hours = totalSeconds / 3600;
    var minutes = (totalSeconds % 3600) / 60;
    var seconds = totalSeconds % 60;
    var text = minutes.toString() + ":";
    if (hours > 0) {
      text = hours.toString() + ":" + (minutes < 10 ? "0" : "") + text;
    }
    return text + (seconds < 10 ? "0" : "") + seconds.toString();
  }
}
