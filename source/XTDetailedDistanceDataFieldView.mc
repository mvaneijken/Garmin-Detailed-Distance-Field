using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class XTDetailedDistanceDataFieldView extends Ui.DataField {
  hidden var settings;
  hidden var lap;
  hidden var layout;
  hidden var unitMeters = 1000;
  // The label texts are loaded once; loading a resource allocates a new string every time. The
  // second line has one label, the one of the content chosen in the settings.
  hidden var labelText;
  hidden var secondLineLabel;
  // "LL 1.234": rebuilt only when the lap, the unit or the settings change, and every update while
  // it shows the time of the current lap.
  hidden var secondLineText;

  function initialize() {
    DataField.initialize();
    logBuild();
    settings = new Settings();
    settings.load();
    lap = new LapTracker();
    layout = new Layout();
    labelText = Ui.loadResource(Rez.Strings.label);
    loadSecondLineLabel();
    refreshUnit();
    buildSecondLineText();
  }

  // Called by the app when the user changes a setting.
  function onSettingsChanged() {
    settings.load();
    layout.invalidate();
    loadSecondLineLabel();
    buildSecondLineText();
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
    if (info has :timerTime) {
      lap.onTimer(info.timerTime);
    }
  }

  // Display the value you computed here. This will be called
  // once a second when the data field is visible.
  function onUpdate(dc) {
    // The device unit can change while the field runs and no event reports it.
    refreshUnit();
    // The time of the current lap changes every second; the other contents only at a lap boundary.
    if (settings.secondLine == 3) {
      buildSecondLineText();
    }
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
        secondLineText,
        layout.justification
      );
    }
  }

  function onTimerLap() {
    lap.onLap();
    buildSecondLineText();
  }

  function onWorkoutStepComplete() {
    lap.onLap();
    buildSecondLineText();
  }

  // The timer was reset (activity saved or discarded): forget the laps of the previous activity.
  function onTimerReset() {
    lap.reset();
    buildSecondLineText();
  }

  hidden function buildSecondLineText() {
    secondLineText =
      secondLineLabel + " " + Format.secondLineValue(lap, unitMeters, settings);
  }

  // Only the label of the chosen content is kept in memory.
  hidden function loadSecondLineLabel() {
    var label = Rez.Strings.lastlaplabel;
    if (settings.secondLine == 1) {
      label = Rez.Strings.lastlaptimelabel;
    } else if (settings.secondLine == 2) {
      label = Rez.Strings.lastlappacelabel;
    } else if (settings.secondLine == 3) {
      label = Rez.Strings.laptimelabel;
    } else if (settings.secondLine == 4) {
      label = Rez.Strings.lapnumberlabel;
    }
    secondLineLabel = Ui.loadResource(label);
  }

  // Which build runs: printed once at start in builds without -r, so a measurement can be tied to
  // the .prg it came from. Release builds (-r) get the empty twin. Change the text per step.
  (:debug)
  hidden function logBuild() {
    Sys.println("Lap Distance build: phase2-second-line");
  }

  (:release)
  hidden function logBuild() {}

  // Reads the device unit; the "LL" text is rebuilt only when the unit changed.
  hidden function refreshUnit() {
    var meters = Format.MILE_METERS;
    if (Sys.getDeviceSettings().distanceUnits == System.UNIT_METRIC) {
      meters = 1000;
    }
    if (meters != unitMeters) {
      unitMeters = meters;
      buildSecondLineText();
    }
  }
}
