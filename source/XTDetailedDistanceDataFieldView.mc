using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;

class XTDetailedDistanceDataFieldView extends Ui.DataField {
  hidden var currentLapDistance = 0;
  hidden var onTimerLapDistance = 0;
  hidden var distance = 0;
  //hidden var distanceUnits = null;

  hidden var lastLapDistance = 0;
  hidden var showLastLap = false;
  hidden var prevLapDistance = 0;
  hidden var screenHeight = 0;
  hidden var labelResource = Rez.Strings.label;
  hidden var lastLabLabelResource = Rez.Strings.lastlaplabel;
  hidden var deviceSettings = Sys.getDeviceSettings();
  hidden var zeroToOneDigits = 3;
  hidden var oneToTenDigits = 2;
  hidden var tenToHundredDigits = 2;
  hidden var hundredOnwardsDigits = 1;
  hidden var valuePosY = 0;
  hidden var valueFont = Gfx.FONT_NUMBER_THAI_HOT;
  hidden var labelFont = Gfx.FONT_SYSTEM_XTINY;
  hidden var lastValueFont = Gfx.FONT_XTINY;
  hidden var width = 0;
  hidden var height = 0;
  hidden var overrideSizing = App.Properties.getValue("overridesizeing");
  //hidden var version = deviceSettings.monkeyVersion;
  //hidden var versionString = Lang.format("$1$.$2$.$3$", version);
  //hidden var majorVersionString = Lang.format("$1$", version);
  //hidden var devicePartNumber = null;
  //hidden var debugMode = App.Properties.getValue("debugmode");
  //hidden var firmwareVersion;
  //hidden var firmwareVersionString = "";
  //hidden var firmwareVersionMajorMinorString = "";
  //hidden var firmwareVersionNumber = 0;
  //hidden var systemStats = Sys.getSystemStats();
  hidden var hideLabel = false;
  hidden var lastLapDistanceString = "";

  function initialize() {
    //writeDebug("-------------- initialize --------------");

    DataField.initialize();

    lastLapDistanceString = Functions.setDistStr(
      distance,
      zeroToOneDigits,
      oneToTenDigits,
      tenToHundredDigits,
      hundredOnwardsDigits
    );
    showLastLap = Functions.getShowLastLapProp();
    //writeDebug("initialize - showLastLap: " + showLastLap);

    screenHeight = deviceSettings.getDeviceSettings().screenHeight;
    //writeDebug("initialize - screenHeight: " + screenHeight);
    //devicePartNumber = Functions.getDevicePartNumber();
    //writeDebug("initialize - devicePartNumber: " + devicePartNumber.toString());

    //firmwareVersion = deviceSettings.firmwareVersion;
    //firmwareVersionString = Lang.format("$1$$2$", firmwareVersion);
    //firmwareVersionNumber = firmwareVersionString.toNumber();
    //firmwareVersionMajorMinorString = Lang.format("$1$.$2$", firmwareVersion);
    //writeDebug("initialize - firmwareVersion: " + firmwareVersionMajorMinorString + " (as number:" + firmwareVersionString + ")");

    //Digits
    zeroToOneDigits = App.Properties.getValue("zerotoone");
    //writeDebug("initialize - zeroToOneDigits: " + zeroToOneDigits);
    oneToTenDigits = App.Properties.getValue("onetoten");
    //writeDebug("initialize - oneToTenDigits: " + oneToTenDigits);
    tenToHundredDigits = App.Properties.getValue("tentohundred");
    //writeDebug("initialize - tenToHundredDigits: " + tenToHundredDigits);
    hundredOnwardsDigits = App.Properties.getValue("zerotoone");
    //writeDebug("initialize - hundredOnwardsDigits: " + hundredOnwardsDigits);

    //Hide Label
    hideLabel = App.Properties.getValue("hideLabel");
  }

  // Set your layout here. Anytime the size of obscurity of
  // the draw context is changed this will be called.
  function onLayout(dc) {}

  // The given info object contains all the current workout
  // information. Calculate a value and save it locally in this method.
  function compute(info) {
    // See Activity.Info in the documentation for available information.
    if (info has :elapsedDistance) {
      if (info.elapsedDistance != null) {
        distance = info.elapsedDistance != null ? info.elapsedDistance : 0;
        currentLapDistance = distance - onTimerLapDistance;
      } else {
        currentLapDistance = 0.0;
      }
    }
  }

  function onUpdate(dc) {
    // Get showLastLapp value
    showLastLap = Functions.getShowLastLapProp();

    //Digits
    zeroToOneDigits = App.Properties.getValue("zerotoone");
    oneToTenDigits = App.Properties.getValue("onetoten");
    tenToHundredDigits = App.Properties.getValue("tentohundred");
    hundredOnwardsDigits = App.Properties.getValue("hundredonwards");
    hideLabel = App.Properties.getValue("hideLabel");

    var lapDistanceString = Functions.setDistStr(
      currentLapDistance,
      zeroToOneDigits,
      oneToTenDigits,
      tenToHundredDigits,
      hundredOnwardsDigits
    );

    width = dc.getWidth();
    height = dc.getHeight();

    var backgroundColor = getBackgroundColor();
    // set foreground color
    dc.setColor(
      backgroundColor == Gfx.COLOR_BLACK ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK,
      Gfx.COLOR_TRANSPARENT
    );
    //writeDebug("onUpdate - foreground color = " + ((backgroundColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK) + ", backgroundColor = " + ((backgroundColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE));

    var valueFontHeight = Gfx.getFontHeight(valueFont);
    // var valueFontDimensions = dc.getTextDimensions(
    //   lapDistanceString,
    //   valueFont
    // );
    var labelFontHeight = Gfx.getFontHeight(labelFont);
    if (hideLabel == true) {
      labelFontHeight = 0;
    }
    // var labelFontDimensions = dc.getTextDimensions(
    //   Ui.loadResource(labelResource),
    //   labelFont
    // );
    // if (hideLabel == true) {
    //   labelFontDimensions = 0;
    // }
    var labelPosY = 0;
    var lastValueFontHeight = Gfx.getFontHeight(lastValueFont);
    // var lastValueFontDimensions = dc.getTextDimensions(
    //   lastLapDistanceString,
    //   lastValueFont
    // );
    var lastValuePosY = 0;
    // var combinedFontHeight = labelFontHeight + valueFontHeight + lastValueFontHeight;
    var justification = Functions.getTextJustification(DataField);
    var justificationLValue = Functions.getTextJustificationLValue(DataField);
    var startPosX = Functions.getStartPosX(width, DataField);
    var valuePosY = 0;

    if (Functions.isSingleFieldLayout(DataField)) {
      //writeDebug("**************");
      valueFont = Gfx.FONT_NUMBER_THAI_HOT;
      valueFontHeight = Gfx.getFontHeight(valueFont);
      //   valueFontDimensions = dc.getTextDimensions(lapDistanceString, valueFont);

      valuePosY = height / 2;
      labelPosY = valuePosY - (labelFontHeight / 2 + valueFontHeight / 2);
      lastValuePosY =
        valuePosY + (valueFontHeight / 2 + lastValueFontHeight / 2);

      if (hideLabel == false) {
        dc.drawText(
          startPosX,
          labelPosY,
          labelFont,
          Ui.loadResource(labelResource),
          justification
        );
      }
      //writeDebug("isSingleFieldLayout - labelPosY = " + labelPosY);
      dc.drawText(
        startPosX,
        valuePosY,
        valueFont,
        lapDistanceString,
        justification
      );
      //writeDebug("isSingleFieldLayout - valuePosY = "+ valuePosY);
      if (showLastLap == true) {
        lastLapDistanceString =
          Ui.loadResource(lastLabLabelResource) +
          " " +
          Functions.setDistStr(
            lastLapDistance,
            zeroToOneDigits,
            oneToTenDigits,
            tenToHundredDigits,
            hundredOnwardsDigits
          );
        //writeDebug("isSingleFieldLayout - lastValuePosY = " + lastValuePosY);
        dc.drawText(
          startPosX,
          lastValuePosY,
          lastValueFont,
          lastLapDistanceString,
          justificationLValue
        );
      }
      //writeDebug("**************");
    } else {
      //writeDebug("**************");
      valueFont = Functions.getValueFont(
        dc,
        lapDistanceString,
        hideLabel,
        showLastLap,
        labelFont,
        lastValueFont,
        overrideSizing,
        App
      );
      valueFontHeight = Gfx.getFontHeight(valueFont);
      //   valueFontDimensions = dc.getTextDimensions(lapDistanceString, valueFont);

      var obscurityFlags = DataField.getObscurityFlags();
      if (hideLabel == false || obscurityFlags == 7) {
        valuePosY = height / 2;
      } else {
        valuePosY = height / 3;
      }
      if (hideLabel == false) {
        labelPosY = valuePosY - (valueFontHeight / 2 + labelFontHeight / 2);
        if (labelPosY - labelFontHeight / 2 < 0 + labelFontHeight / 2) {
          //writeDebug("isMultiFieldLayout - labelPosY = " + labelPosY + " Correction to 0");
          labelPosY = 0 + labelFontHeight / 2;
        }
      }
      lastValuePosY =
        valuePosY + (valueFontHeight / 2 + lastValueFontHeight / 2);

      if (obscurityFlags == 3 or obscurityFlags == 6) {
        //writeDebug("isMultiFieldLayout - Top Left/Right location");
        lastValuePosY = height - lastValueFontHeight / 2;
        if (showLastLap != true) {
          lastValuePosY = 0;
        }
        valuePosY =
          lastValuePosY - (valueFontHeight / 2 + lastValueFontHeight / 2);
        labelPosY = valuePosY - (valueFontHeight / 2 + labelFontHeight / 2);
      }
      if (obscurityFlags == 9 or obscurityFlags == 12) {
        //writeDebug("isMultiFieldLayout - Bottom Left/Right location");
        labelPosY = 0 + labelFontHeight / 2;
        valuePosY = labelPosY + (valueFontHeight / 2 + labelFontHeight / 2);
        lastValuePosY =
          valuePosY + (valueFontHeight / 2 + lastValueFontHeight / 2);
      }
      if (hideLabel == true && obscurityFlags == 7) {
        //writeDebug("isMultiFieldLayout - Bottom center top");
        lastValuePosY = height - lastValueFontHeight / 2;
        if (showLastLap != true) {
          lastValuePosY = 0;
        }
        valuePosY =
          lastValuePosY - (valueFontHeight / 2 + lastValueFontHeight / 2);
      }
      if (hideLabel == false) {
        dc.drawText(
          startPosX,
          labelPosY,
          labelFont,
          Ui.loadResource(labelResource),
          justification
        );
        //writeDebug("isMultiFieldLayout - labelPosY = "+ labelPosY);
      }
      dc.drawText(
        startPosX,
        valuePosY,
        valueFont,
        lapDistanceString,
        justification
      );
      //writeDebug("isMultiFieldLayout - valuePosY = "+ valuePosY);
      if (showLastLap == true) {
        lastLapDistanceString =
          Ui.loadResource(lastLabLabelResource) +
          " " +
          Functions.setDistStr(
            lastLapDistance,
            zeroToOneDigits,
            oneToTenDigits,
            tenToHundredDigits,
            hundredOnwardsDigits
          );
        //writeDebug("isMultiFieldLayout - lastValuePosY = " + lastValuePosY);
        dc.drawText(
          startPosX,
          lastValuePosY,
          lastValueFont,
          lastLapDistanceString,
          justificationLValue
        );
      }
      //writeDebug("**************");
    }
    //Debug info
    //if (debugMode == true) {
      //systemStats = Sys.getSystemStats();
      //writeDebug("debug info - system total memory bytes: " + systemStats.totalMemory.toString());
      //writeDebug("debug info - system free memory bytes: " + systemStats.freeMemory.toString());
      //writeDebug("debug info - system used memory bytes: " + systemStats.usedMemory.toString());
      //writeDebug("debug info - system battery %: " + systemStats.battery.toString());
      //writeDebug("debug info - width: " + width);
      //writeDebug("debug info - height: " + height);
      //writeDebug("debug info - backgroundColor: " + backgroundColor);
      //writeDebug("debug info - valueFont: " + valueFont);
      //writeDebug("debug info - valueFontHeight: " + valueFontHeight);
      //writeDebug("debug info - valueFontDimensions: " + valueFontDimensions);
      //writeDebug("debug info - valuePosY: " + valuePosY);
      //writeDebug("debug info - labelFont: " + labelFont);
      //writeDebug("debug info - labelFontHeight: " + labelFontHeight);
      //writeDebug("debug info - labelFontDimensions: " + labelFontDimensions);
      //writeDebug("debug info - labelPosY: " + labelPosY);
      //writeDebug("debug info - lastValueFont: " + lastValueFont);
      //writeDebug("debug info - lastValueFontHeight: " + lastValueFontHeight);
      //writeDebug("debug info - lastValueFontDimensions: " + lastValueFontDimensions);
      //writeDebug("debug info - lastValuePosY: " + lastValuePosY);
      //writeDebug("debug info - combinedFontHeight: " + combinedFontHeight);
      //writeDebug("debug info - justification: " + justification);
      //writeDebug("debug info - justificationLValue: " + justificationLValue);
      //writeDebug("debug info - startPosX: " + startPosX);
      //writeDebug("debug info - devicePartNumber: " + devicePartNumber);
      //writeDebug("debug info - getObscurityFlags: " + DataField.getObscurityFlags());
      //writeDebug("debug info - justification: " + getTextJustification(DataField));
      //writeDebug("-------------- end --------------");
    //}
  }

  function onWorkoutStepComplete(
    lastLapDistance,
    onTimerLapDistance,
    prevLapDistance
  ) {
    lastLapDistance = distance - prevLapDistance;
    onTimerLapDistance = distance;
    prevLapDistance = distance;
  }

  function onTimerLap() {
    lastLapDistance = distance - prevLapDistance;
    onTimerLapDistance = distance;
    prevLapDistance = distance;
  }
}

//deviceID list:
//fr920xt = "006-B1765-00"
//fenix3 = "006-B2050-00"
//fenix3_hr = "006-B2413-00"
//fenixchronos = "006-B2432-00"
//fenix5s = "006-B2544-00"
//fenix5x = "006-B2604-00"
//fr935 = "006-B2691-00"
//fenix5 = "006-B2697-00"
//vivoactive3 = "006-B2700-00"
//fr645	= "006-B2886-00"
//fr645m = "006-B2888-00"
//fenix5splus = "006-B2900-00"
//vivoactive3m = "006-B2988-00"
//vivoactive3mlte = "006-B3066-00"
//fenix5plus = "006-B3110-00"
//fenix5xplus = "006-B3111-00"
//fr245 = "006-B3076-00"
//fr245music = "006-B3077-00"
//fr945 = "006-B3113-00"
//approachs60 = "006-B2656-00"
//d2bravo = "006-B2262-00"
//d2bravo_titanium = "006-B2547-00"
//d2charlie = "006-B2819-00"
//d2delta = "006-B3197-00"
//d2deltapx = "006-B3198-00"
//d2deltas = "006-B3196-00"
//descentmk1 = "006-B2859-00"
//edge1030 = "006-B2713-00"
//edge1030bontrager = "006-B3095-00"
//edge130 = "006-B2909-00"
//edge520plus = "006-B3112-00"
//edge820 = "006-B2530-00"
//edgeexplore = "006-B3011-00"
//edge_1000 = "006-B1836-00"
//edge_520 = "006-B2067-00"
//epix = "006-B1988-00"

//gpsmap66 = "006-B3028-00"
//oregon7xx = "006-B2512-00"
//rino7xx = "006-B2444-00"
//vivoactive_hr = "006-B2337-00"
//marqathlete = "006-B3251-00"
//fenix6pro = "006-B3290-00"
//fenix6 = "006-B3289-00"
//fenix6s = "006-B3287-00"
//fenix6spro = "006-B3288-00"
//fenix6xpro = "006-B3291-00"
//vivoactive4 = "006-B3225-00"
//vivoactive4s = "006-B3224-00"
//venu = "006-B3226-00"
