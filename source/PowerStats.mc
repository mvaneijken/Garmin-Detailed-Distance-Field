// Rolling and lap average power (roadmap 3.2). One sample per compute (about one per second), so a window of
// n samples is about n seconds. A missing sample (no power meter, or a dropout) is not added: it would pull the
// average down to 0 W, which is a real value (coasting). Only the t1 devices have it.
(:t1)
class PowerStats {
  // The longest window: 30 s.
  const RING = 30;

  hidden var samples;
  // Where the next sample goes, and how many are stored (up to RING).
  hidden var next = 0;
  hidden var count = 0;
  hidden var lapSum = 0;
  hidden var lapCount = 0;

  function initialize() {
    samples = new [RING];
  }

  function add(watts) {
    samples[next] = watts;
    next = (next + 1) % RING;
    if (count < RING) {
      count += 1;
    }
    lapSum += watts;
    lapCount += 1;
  }

  // Average of the newest seconds samples, in whole watts. With fewer samples than the window it is the
  // average of the ones there are. null without samples.
  function average(seconds) {
    var n = seconds < count ? seconds : count;
    if (n < 1) {
      return null;
    }
    var sum = 0;
    for (var age = 0; age < n; age += 1) {
      sum += samples[(next - 1 - age + RING) % RING];
    }
    return round(sum, n);
  }

  // Average of the samples since the lap started, or null.
  function lapAverage() {
    return lapCount < 1 ? null : round(lapSum, lapCount);
  }

  function onLap() {
    lapSum = 0;
    lapCount = 0;
  }

  function clear() {
    next = 0;
    count = 0;
    onLap();
  }

  // sum / n in whole watts, half up.
  hidden function round(sum, n) {
    return (sum.toFloat() / n + 0.5).toNumber();
  }
}
