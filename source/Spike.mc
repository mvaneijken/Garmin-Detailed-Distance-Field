using Toybox.AntPlus;
using Toybox.System as Sys;

// The Stryd spike (roadmap 3.1), from the Connect IQ side: which ANT+ profiles does the sensor paired to the
// watch broadcast, and what data do they carry? A spike build listens to the Running Dynamics profile (ground
// contact time, vertical oscillation, step length, ...) and the Bike Power profile (power, which running power
// meters use too) and prints one line per update. It needs the Ant permission, so it has its own manifest
// (tools/probe/manifest-spike.xml) and jungle (spike.jungle) and is never part of a normal build: the
// (:spike) code is excluded everywhere else and the (:nospike) twins do nothing. Lines (see docs/STRYD-SPIKE.md):
//
//   S,rd,<clock>,<ground contact time ms>,<vertical oscillation mm>,<stance time>,<step length mm>,<cadence>,<vertical ratio>,<balance>
//   S,power,<clock>,<watts>,<power sensor type>
//   S,state,<clock>,<profile>,<device state>,<ANT device number>
//   S,mfr,<clock>,<profile>,<manufacturer id>,<model>,<hardware revision>
//   S,tick,<clock>,<profile states ...>, every 10 seconds, so a silent sensor shows as such
//
// What it cannot show: the proprietary Stryd pages (form power, air power, leg spring stiffness), which a
// Connect IQ app does not receive. That is the question for the ANT+ capture tools in the spike protocol.
module Spike {
  (:spike)
  var runningDynamics = null;
  (:spike)
  var bikePower = null;
  (:spike)
  var seconds = 0;

  (:spike)
  function start() {
    try {
      runningDynamics = new AntPlus.RunningDynamics(new SpikeRunningListener());
      bikePower = new AntPlus.BikePower(new SpikePowerListener());
    } catch (exception) {
      Sys.println("S,error," + Sys.getTimer() + "," + exception.getErrorMessage());
    }
  }

  // Called every compute (about once a second).
  (:spike)
  function tick() {
    seconds += 1;
    if (seconds % 10 == 0 && runningDynamics != null) {
      Sys.println(
        "S,tick," + Sys.getTimer() + ",rd," + stateText(runningDynamics.getDeviceState()) + ",power," +
          stateText(bikePower.getDeviceState())
      );
    }
  }

  (:spike)
  function text(value) {
    return value == null ? "null" : value.toString();
  }

  (:spike)
  function stateText(deviceState) {
    return text(deviceState.state) + "/" + text(deviceState.deviceNumber);
  }

  (:spike)
  function runningDynamicsLine(clock, data) {
    return (
      "S,rd," + clock + "," + text(data.groundContactTime) + "," + text(data.verticalOscillation) + "," +
      text(data.stanceTime) + "," + text(data.stepLength) + "," + text(data.cadence) + "," +
      text(data.verticalRatio) + "," + text(data.groundContactBalance)
    );
  }

  (:spike)
  function manufacturerLine(clock, profile, data) {
    return (
      "S,mfr," + clock + "," + profile + "," + text(data.manufacturerId) + "," + text(data.modelNumber) + "," +
      text(data.hwRevision)
    );
  }

  (:nospike)
  function start() {}

  (:nospike)
  function tick() {}
}

(:spike)
class SpikeRunningListener extends AntPlus.RunningDynamicsListener {
  function initialize() {
    RunningDynamicsListener.initialize();
  }

  function onRunningDynamicsUpdate(data) {
    Sys.println(Spike.runningDynamicsLine(Sys.getTimer(), data));
  }

  function onDeviceStateUpdate(data) {
    Sys.println("S,state," + Sys.getTimer() + ",rd," + Spike.stateText(data));
  }

  function onManufacturerInfoUpdate(data) {
    Sys.println(Spike.manufacturerLine(Sys.getTimer(), "rd", data));
  }
}

(:spike)
class SpikePowerListener extends AntPlus.BikePowerListener {
  function initialize() {
    BikePowerListener.initialize();
  }

  function onCalculatedPowerUpdate(data) {
    Sys.println("S,power," + Sys.getTimer() + "," + Spike.text(data.power) + "," + Spike.text(data.powerSensorType));
  }

  function onDeviceStateUpdate(data) {
    Sys.println("S,state," + Sys.getTimer() + ",power," + Spike.stateText(data));
  }

  function onManufacturerInfoUpdate(data) {
    Sys.println(Spike.manufacturerLine(Sys.getTimer(), "power", data));
  }
}
