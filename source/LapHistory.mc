// A ring buffer of the finished laps (roadmap 2.1): distance, duration and, when the device knows it, the
// lap trigger. The newest lap has age 0. When the buffer is full, a new lap replaces the oldest one.
// The three values live in parallel arrays: no object per lap, so a lap costs a few bytes.
//
// Only devices with enough memory have it (the t1 annotation, see tools/Get-DeviceTiers.ps1); T0 gets the
// empty twins of LapLog instead.
(:t1)
class LapHistory {
  // A lap shorter than this in both distance (m) and time (ms) is an empty lap, see add().
  const MIN_DISTANCE = 1.0;
  const MIN_DURATION = 1000;

  // Number of laps stored.
  var count = 0;
  hidden var capacity;
  hidden var distances;
  hidden var durations;
  hidden var triggers;
  // Where the next lap goes.
  hidden var next = 0;

  function initialize(size) {
    capacity = size;
    distances = new [size];
    durations = new [size];
    triggers = new [size];
  }

  // Stores a finished lap. Returns false for an empty lap (under 1 m and under 1 s): that is what a second
  // event at the same boundary produces (finding C3), and it would waste a slot and skew a chart.
  function add(distance, duration, trigger) {
    if (distance < MIN_DISTANCE && duration < MIN_DURATION) {
      return false;
    }
    distances[next] = distance;
    durations[next] = duration;
    triggers[next] = trigger;
    next = (next + 1) % capacity;
    if (count < capacity) {
      count += 1;
    }
    return true;
  }

  function distanceAt(age) {
    var slot = slotOf(age);
    return slot < 0 ? null : distances[slot];
  }

  function durationAt(age) {
    var slot = slotOf(age);
    return slot < 0 ? null : durations[slot];
  }

  function triggerAt(age) {
    var slot = slotOf(age);
    return slot < 0 ? null : triggers[slot];
  }

  function clear() {
    count = 0;
    next = 0;
  }

  // The array slot of the lap that is age laps old, or -1 when there is no such lap.
  hidden function slotOf(age) {
    if (age < 0 || age >= count) {
      return -1;
    }
    return (next - 1 - age + capacity) % capacity;
  }
}
