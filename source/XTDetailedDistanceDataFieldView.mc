using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class XTDetailedDistanceDataFieldView extends Ui.DataField {
  hidden var settings;
  hidden var lap;
  hidden var layout;
  hidden var unitMeters = 1000;
  hidden var labelResource = Rez.Strings.label;
  hidden var lastLapLabelResource = Rez.Strings.lastlaplabel;

  function initialize() {
    DataField.initialize();
    settings = new Settings();
    settings.load();
    lap = new LapTracker();
    layout = new Layout();
  }

  // Called by the app when the user changes a setting.
  function onSettingsChanged() {
    settings.load();
  }

  // Anytime the size or obscurity of the draw context changes this is called.
  function onLayout(dc) {}

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
    setDeviceSettingsDependentVariables();

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

    layout.update(
      dc,
      DataField.getObscurityFlags(),
      settings,
      lapDistanceString
    );

    if (settings.hideLabel == false) {
      dc.drawText(
        layout.startPosX,
        layout.labelPosY,
        layout.labelFont,
        Ui.loadResource(labelResource),
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
        Ui.loadResource(lastLapLabelResource) +
          " " +
          Format.distanceString(lap.previousLap, unitMeters, settings),
        layout.justification
      );
    }
  }

  function onTimerLap() {
    lap.onLap();
  }

  function onWorkoutStepComplete() {
    lap.onLap();
  }

  function setDeviceSettingsDependentVariables() {
    if (Sys.getDeviceSettings().distanceUnits == System.UNIT_METRIC) {
      unitMeters = 1000;
    } else {
      unitMeters = 1610;
    }
  }
}
