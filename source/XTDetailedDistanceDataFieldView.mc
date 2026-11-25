using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class XTDetailedDistanceDataFieldView extends Ui.DataField {
  hidden var settings;
  hidden var lap;
  hidden var layout;
  hidden var unitMeters = 1000;
  // The label texts are loaded once; loading a resource allocates a new string every time.
  hidden var labelText;
  hidden var lastLapLabelText;
  // "LL 1.234": rebuilt only when the previous lap, the unit or the settings change.
  hidden var lastLapText;

  function initialize() {
    DataField.initialize();
    logBuild();
    settings = new Settings();
    settings.load();
    lap = new LapTracker();
    layout = new Layout();
    labelText = Ui.loadResource(Rez.Strings.label);
    lastLapLabelText = Ui.loadResource(Rez.Strings.lastlaplabel);
    refreshUnit();
    buildLastLapText();
  }

  // Called by the app when the user changes a setting.
  function onSettingsChanged() {
    settings.load();
    layout.invalidate();
    buildLastLapText();
  }

  // Called when the size or the obscurity of the draw context changes.
  function onLayout(dc) {
    layout.invalidate();
  }

  // The given info object contains all the current workout
  // information. Calculate a value and save it locally in this method.
  function compute(info) {
    if (info has :elapsedDistance) {
      lap.onDistance(info.elapsedDistance);
    }
  }

  // Display the value you computed here. This will be called
  // once a second when the data field is visible.
  function onUpdate(dc) {
    // The device unit can change while the field runs and no event reports it.
    refreshUnit();
    var lapDistanceString = Format.distanceString(
      lap.currentLap,
      unitMeters,
      settings
    );

    var backgroundColor = getBackgroundColor();
    dc.setColor(
      backgroundColor == Gfx.COLOR_BLACK ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK,
      Gfx.COLOR_TRANSPARENT
    );

    if (!layout.isValid(lapDistanceString.length())) {
      layout.update(
        dc,
        DataField.getObscurityFlags(),
        settings,
        lapDistanceString
      );
    }

    if (settings.hideLabel == false) {
      dc.drawText(
        layout.startPosX,
        layout.labelPosY,
        layout.labelFont,
        labelText,
        layout.justification
      );
    }
    dc.drawText(
      layout.startPosX,
      layout.valuePosY,
      layout.valueFont,
      lapDistanceString,
      layout.justification
    );
    if (settings.showLastLap == true) {
      dc.drawText(
        layout.startPosX,
        layout.lastValuePosY,
        layout.lastValueFont,
        lastLapText,
        layout.justification
      );
    }
  }

  function onTimerLap() {
    lap.onLap();
    buildLastLapText();
  }

  function onWorkoutStepComplete() {
    lap.onLap();
    buildLastLapText();
  }

  hidden function buildLastLapText() {
    lastLapText =
      lastLapLabelText +
      " " +
      Format.distanceString(lap.previousLap, unitMeters, settings);
  }

  // Which build runs: printed once at start in builds without -r, so a measurement can be tied to
  // the .prg it came from. Release builds (-r) get the empty twin. Change the text per step.
  (:debug)
  hidden function logBuild() {
    Sys.println("Lap Distance build: phase1-layout-cache");
  }

  (:release)
  hidden function logBuild() {}

  // Reads the device unit; the "LL" text is rebuilt only when the unit changed.
  hidden function refreshUnit() {
    var meters = 1610;
    if (Sys.getDeviceSettings().distanceUnits == System.UNIT_METRIC) {
      meters = 1000;
    }
    if (meters != unitMeters) {
      unitMeters = meters;
      buildLastLapText();
    }
  }
}
