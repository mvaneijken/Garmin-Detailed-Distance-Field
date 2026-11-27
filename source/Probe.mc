using Toybox.System as Sys;

// Lap probe for the device test of roadmap 0.5 (docs/LAP-TEST-PROTOCOL.md). Which timer events the watch
// sends at a lap boundary can only be seen on a device, so a probe build prints one short line per event:
//
//   <P or C>,<event>,<getTimer ms>,<timerTime ms>,<distance m>,<current lap m>,<previous lap m>,<lap number>
//
// P is printed in the callback, C at the first compute after an event (what the field shows from then on).
// tools/probe/compare_lap_probe.py reads the lines. Never printed per update: the small device log rolls
// over after about 5 KB.
//
// The (:probe) code is excluded by monkey.jungle and compiled in by probe.jungle; every other build gets the
// empty (:noprobe) twins, so the probe changes no behaviour and no value.
module Probe {
  (:probe)
  var pending = false;

  (:probe)
  function event(name, lap) {
    pending = true;
    log("P", name, lap);
  }

  (:probe)
  function afterCompute(lap) {
    if (pending) {
      pending = false;
      log("C", "after", lap);
    }
  }

  (:probe)
  function log(kind, name, lap) {
    Sys.println(line(kind, name, Sys.getTimer(), lap));
  }

  (:probe)
  function line(kind, name, clock, lap) {
    return (
      kind + "," + name + "," + clock + "," + lap.timer + "," + lap.distance + "," +
      lap.currentLap + "," + lap.previousLap + "," + lap.lapNumber
    );
  }

  (:noprobe)
  function event(name, lap) {}

  (:noprobe)
  function afterCompute(lap) {}
}
