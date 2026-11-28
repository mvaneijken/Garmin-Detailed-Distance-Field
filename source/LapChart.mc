using Toybox.Graphics as Gfx;

// The lap bar chart behind the value (roadmap 4.1, 4.2, 4.4): one bar per finished lap, oldest on the left,
// and the lap in progress as a growing bar on the right. Bar height = lap distance, scaled to the longest bar
// in view. The fastest and the slowest finished lap in view get their own colour. It reads the lap history, so
// it exists on T1 and above only (the t1 annotation); T0 devices get the empty twins.
//
// What is not here: separating active and recovery steps of a workout (roadmap 4.3). A data field cannot read
// the workout step (see the notes at roadmap 2.2).

// The numbers behind the bars, kept in arrays that are filled in place: no allocation per update.
(:t1)
class LapChartModel {
  static const RANK_NONE = 0;
  static const RANK_FASTEST = 1;
  static const RANK_SLOWEST = 2;

  // Bars that fit in the field, and bars in use (the current lap is the last one).
  var slots;
  var count = 0;
  hidden var fractions;
  hidden var ranks;

  function initialize(slotCount) {
    slots = slotCount;
    fractions = new [slotCount];
    ranks = new [slotCount];
  }

  // history: the finished laps (LapHistory); currentLap: the distance of the lap in progress (m).
  function update(history, currentLap) {
    var finished = history.count < slots - 1 ? history.count : slots - 1;
    count = finished + 1;

    // scale: the longest bar in view; the slowest and the fastest pace among the finished laps
    var longest = currentLap;
    var fastest = -1.0;
    var slowest = -1.0;
    for (var bar = 0; bar < finished; bar += 1) {
      var age = finished - 1 - bar;
      var distance = history.distanceAt(age);
      if (distance > longest) {
        longest = distance;
      }
      var speed = speedOf(distance, history.durationAt(age));
      if (speed > 0) {
        if (fastest < 0 || speed > fastest) {
          fastest = speed;
        }
        if (slowest < 0 || speed < slowest) {
          slowest = speed;
        }
      }
    }
    if (longest < 1.0) {
      longest = 1.0;
    }

    for (var bar = 0; bar < finished; bar += 1) {
      var age = finished - 1 - bar;
      var distance = history.distanceAt(age);
      fractions[bar] = distance / longest;
      ranks[bar] = RANK_NONE;
      var speed = speedOf(distance, history.durationAt(age));
      if (speed > 0 && fastest > slowest) {
        if (speed == fastest) {
          ranks[bar] = RANK_FASTEST;
        } else if (speed == slowest) {
          ranks[bar] = RANK_SLOWEST;
        }
      }
    }
    fractions[finished] = currentLap / longest;
    ranks[finished] = RANK_NONE;
  }

  function fractionAt(bar) {
    return fractions[bar];
  }

  function rankAt(bar) {
    return ranks[bar];
  }

  // meters per millisecond; 0 when the lap has no time
  hidden function speedOf(distance, duration) {
    return duration > 0 ? distance / duration : 0.0;
  }
}

module LapChart {
  // The smallest field that gets a chart (roadmap 4.4): a large half screen or a full screen.
  (:t1)
  const MIN_WIDTH = 110;
  (:t1)
  const MIN_HEIGHT = 90;

  (:t1)
  var model = null;

  (:t1)
  function fits(width, height) {
    return width >= MIN_WIDTH && height >= MIN_HEIGHT;
  }

  // Draws the bars on the bottom edge of the field, before the text. currentLap is the distance in progress.
  (:t1)
  function draw(dc, background, currentLap) {
    var width = dc.getWidth();
    var height = dc.getHeight();
    if (!fits(width, height)) {
      return;
    }
    // about 16 pixels per bar, between 4 and 12 bars
    var slots = width / 16;
    slots = slots < 4 ? 4 : (slots > 12 ? 12 : slots);
    if (model == null || model.slots != slots) {
      model = new LapChartModel(slots);
    }
    model.update(LapLog.history, currentLap);

    var gap = 2;
    var barWidth = (width - gap * (slots - 1)) / slots;
    var maxHeight = height * 9 / 10;
    for (var bar = 0; bar < model.count; bar += 1) {
      var barHeight = (model.fractionAt(bar) * maxHeight).toNumber();
      if (barHeight < 1) {
        barHeight = 1;
      }
      var x = (slots - model.count + bar) * (barWidth + gap);
      dc.setColor(colorFor(model.rankAt(bar), bar == model.count - 1, background), Gfx.COLOR_TRANSPARENT);
      dc.fillRectangle(x, height - barHeight, barWidth, barHeight);
    }
  }

  // Muted greys for the laps so the text on top stays readable; green and red for the extremes.
  (:t1)
  function colorFor(rank, isCurrent, background) {
    var dark = background == Gfx.COLOR_BLACK;
    if (rank == 1) {
      return dark ? Gfx.COLOR_GREEN : Gfx.COLOR_DK_GREEN;
    } else if (rank == 2) {
      return dark ? Gfx.COLOR_RED : Gfx.COLOR_DK_RED;
    }
    if (isCurrent) {
      return dark ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY;
    }
    return dark ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY;
  }

  (:t0)
  function draw(dc, background, currentLap) {}
}
