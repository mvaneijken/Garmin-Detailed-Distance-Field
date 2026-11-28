using Toybox.Activity;

// The second-line contents that come from the sensors of the watch (roadmap 3.2 and 3.3): power, rolling
// and lap average power, cadence and pace. A Stryd paired as power sensor and foot pod arrives here through
// Activity.Info like any other sensor; nothing in the field depends on Stryd.
//
// T1 and above only (the t1 annotation): the T0 devices (16 KB) get the empty twins, and show "--" for
// these contents (the setting list says so). The tier lines come from monkey.jungle.
module SensorLine {
  // The latest values of Activity.Info (null while the watch has none): watts, steps or revolutions per
  // minute, meters per second.
  (:t1)
  var power = null;
  (:t1)
  var cadence = null;
  (:t1)
  var speed = null;

  // Called every compute with the Activity.Info of the watch. The values shown as current are always live;
  // the averages only count samples taken while the timer runs: compute() keeps being called before the
  // start, while paused and after a stop, and a power meter keeps sending then. A watch without a timer
  // state is treated as recording.
  (:t1)
  function sample(info) {
    var watts = info has :currentPower ? info.currentPower : null;
    setSample(
      watts,
      info has :currentCadence ? info.currentCadence : null,
      info has :currentSpeed ? info.currentSpeed : null
    );
    if (!(info has :timerState) || info.timerState == Activity.TIMER_STATE_ON) {
      LapLog.onPower(watts);
    }
  }

  (:t1)
  function setSample(watts, rate, metersPerSecond) {
    power = watts;
    cadence = rate;
    speed = metersPerSecond;
  }

  // The text for a second-line content from 5 on (see Settings.secondLine).
  (:t1)
  function value(content, unitMeters) {
    if (content == 5) {
      return numberString(power);
    } else if (content >= 6 && content <= 8) {
      // 6, 7 and 8 are the windows of 3, 10 and 30 seconds
      return numberString(LapLog.averagePower(content == 6 ? 3 : (content == 7 ? 10 : 30)));
    } else if (content == 9) {
      return numberString(LapLog.lapAveragePower());
    } else if (content == 10) {
      return numberString(cadence);
    }
    return speedPaceString(speed, unitMeters);
  }

  // A whole number, or "--" while the watch has no value.
  (:t1)
  function numberString(number) {
    return number == null ? "--" : number.toString();
  }

  // Pace per kilometer or mile from a speed in meters per second, like Format.paceString; "--:--" while
  // standing still or without speed.
  (:t1)
  function speedPaceString(metersPerSecond, unitMeters) {
    if (metersPerSecond == null || metersPerSecond <= 0) {
      return "--:--";
    }
    var seconds = unitMeters / metersPerSecond;
    if (seconds >= 5999.5) {
      return "--:--";
    }
    return Format.clockString((seconds + 0.5).toNumber());
  }

  // The label resource of a second-line content, in the order of the setting values.
  (:t1)
  function labelId(content) {
    var ids = [
      Rez.Strings.lastlaplabel,
      Rez.Strings.lastlaptimelabel,
      Rez.Strings.lastlappacelabel,
      Rez.Strings.laptimelabel,
      Rez.Strings.lapnumberlabel,
      Rez.Strings.powerlabel,
      Rez.Strings.power3label,
      Rez.Strings.power10label,
      Rez.Strings.power30label,
      Rez.Strings.lappowerlabel,
      Rez.Strings.cadencelabel,
      Rez.Strings.pacelabel,
    ];
    return ids[content];
  }

  (:t0)
  function sample(info) {}

  (:t0)
  function value(content, unitMeters) {
    return "--";
  }

  // T0 knows the first five contents only; a higher value (a setting synced from another watch) shows the
  // default label and "--".
  (:t0)
  function labelId(content) {
    var ids = [
      Rez.Strings.lastlaplabel,
      Rez.Strings.lastlaptimelabel,
      Rez.Strings.lastlappacelabel,
      Rez.Strings.laptimelabel,
      Rez.Strings.lapnumberlabel,
    ];
    return ids[content < 5 ? content : 0];
  }
}
