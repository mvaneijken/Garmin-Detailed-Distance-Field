using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;

class XTDetailedDistanceDataFieldView extends Ui.DataField {
  hidden var currentLapDistance = 0;
  hidden var onTimerLapDistance = 0;
  hidden var distance = 0;
  hidden var kmOrMileInMeters = 1000;
  hidden var distanceUnits = null;
  hidden const ZERO_DISTANCE3 = "0.000";
  hidden const ZERO_DISTANCE2 = "0.00";
  hidden const ZERO_DISTANCE1 = "0.0";
  hidden const ZERO_DISTANCE = "0";
  hidden var lastLapDistance = 0;
  hidden var showLastLap = false;
  hidden var prevLapDistance = 0;
  hidden var screenHeight = 0;
  hidden var labelResource = Rez.Strings.label;
  hidden var lastLabLabelResource = Rez.Strings.lastlaplabel;
  hidden var deviceSettings = Sys.getDeviceSettings();
  hidden var version = deviceSettings.monkeyVersion;
  hidden var versionString = Lang.format("$1$.$2$.$3$", version);
  hidden var majorVersionString = Lang.format("$1$", version);
  hidden var devicePartNumber = null;
  hidden var zeroToOneDigits = 3;
  hidden var oneToTenDigits = 2;
  hidden var tenToHundredDigits = 2;
  hidden var hundredOnwardsDigits = 1;
  hidden var valuePosY = 0;
  hidden var lastLapDistanceString = setDistStr(lastLapDistance);
  hidden var valueFont = Gfx.FONT_NUMBER_THAI_HOT;
  hidden var labelFont = Gfx.FONT_SYSTEM_XTINY;
  hidden var lastValueFont = Gfx.FONT_XTINY;
  hidden var width = 0;
  hidden var height = 0;
  hidden var overrideSizing = App.Properties.getValue("overridesizeing");
  hidden var debugMode = App.Properties.getValue("debugmode");
  hidden var firmwareVersion;
  hidden var firmwareVersionString = "";
  hidden var firmwareVersionMajorMinorString = "";
  hidden var firmwareVersionNumber = 0;
  hidden var systemStats = Sys.getSystemStats();
  hidden var hideLabel = false;

  function initialize() {
    //writeDebug("-------------- initialize --------------");

    DataField.initialize();

    showLastLap = getShowLastLapProp();
    //writeDebug("initialize - showLastLap: " + showLastLap);

    screenHeight = deviceSettings.getDeviceSettings().screenHeight;
    //writeDebug("initialize - screenHeight: " + screenHeight);
    devicePartNumber = getDevicePartNumber();
    //writeDebug("initialize - devicePartNumber: " + devicePartNumber.toString());

    firmwareVersion = deviceSettings.firmwareVersion;
    firmwareVersionString = Lang.format("$1$$2$", firmwareVersion);
    firmwareVersionNumber = firmwareVersionString.toNumber();
    firmwareVersionMajorMinorString = Lang.format("$1$.$2$", firmwareVersion);
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

  // Display the value you computed here. This will be called
  // once a second when the data field is visible.
  function onUpdate(dc) {
    // Get showLastLapp value
    showLastLap = getShowLastLapProp();

    //Digits
    zeroToOneDigits = App.Properties.getValue("zerotoone");
    oneToTenDigits = App.Properties.getValue("onetoten");
    tenToHundredDigits = App.Properties.getValue("tentohundred");
    hundredOnwardsDigits = App.Properties.getValue("hundredonwards");

    setDeviceSettingsDependentVariables();

    var lapDistanceString = setDistStr(currentLapDistance);

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
    var justification = getTextJustification();
    var justificationLValue = getTextJustificationLValue();
    var startPosX = getStartPosX(width);
    var valuePosY = 0;

    if (isSingleFieldLayout()) {
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
          setDistStr(lastLapDistance);
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
      valueFont = getValueFont(dc, lapDistanceString);
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
          setDistStr(lastLapDistance);
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
    if (debugMode == true) {
      systemStats = Sys.getSystemStats();
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
      //writeDebug("debug info - justification: " + getTextJustification());
      //writeDebug("-------------- end --------------");
    }
  }

  function isSingleFieldLayout() {
    return (
      DataField.getObscurityFlags() ==
      (OBSCURE_TOP | OBSCURE_LEFT | OBSCURE_BOTTOM | OBSCURE_RIGHT)
    );
  }

  function getTextJustification() {
    var justification;
    var textCenter = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
    //writeDebug("getTextJustification - textCenter = " + textCenter);
    var textRight = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
    //writeDebug("getTextJustification - textRight = " + textRight);
    var textLeft = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
    //writeDebug("getTextJustification - textLeft = " + textLeft);
    if (
      DataField.getObscurityFlags() == 12 or
      DataField.getObscurityFlags() == 6
    ) {
      justification = textLeft;
    } else if (
      DataField.getObscurityFlags() == 3 or
      DataField.getObscurityFlags() == 9
    ) {
      justification = textRight;
    } else {
      justification = textCenter;
    }
    return justification;
  }

  function getTextJustificationLValue() {
    var justification;
    var textCenter = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
    var textRight = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
    var textLeft = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
    if (
      DataField.getObscurityFlags() == 12 or
      DataField.getObscurityFlags() == 6
    ) {
      justification = textLeft;
    } else if (
      DataField.getObscurityFlags() == 3 or
      DataField.getObscurityFlags() == 9
    ) {
      justification = textRight;
    } else {
      justification = textCenter;
    }
    return justification;
  }

  function getStartPosX(width) {
    var startPosX = 0;
    var margin = Math.round((width / 100) * 2);

    if (
      DataField.getObscurityFlags() == 12 or
      DataField.getObscurityFlags() == 6
    ) {
      startPosX = 0 + margin;
    } else if (
      DataField.getObscurityFlags() == 3 or
      DataField.getObscurityFlags() == 9
    ) {
      startPosX = width - margin;
    } else {
      startPosX = width / 2;
    }
    return startPosX;
  }

  function onTimerLap() {
    lastLapDistance = distance - prevLapDistance;
    onTimerLapDistance = distance;
    prevLapDistance = distance;
  }

  function onWorkoutStepComplete() {
    lastLapDistance = distance - prevLapDistance;
    onTimerLapDistance = distance;
    prevLapDistance = distance;
  }

  function getShowLastLapProp() {
    var showLastLap_prop = App.Properties.getValue("showLastLap_prop");
    if (null == showLastLap_prop) {
      showLastLap = false;
    } else {
      showLastLap = showLastLap_prop;
    }
    return showLastLap;
  }

  function setDistStr(distance) {
    var distStr;
    if (distance > 0) {
      var distanceKmOrMiles = distance / kmOrMileInMeters;
      if (distanceKmOrMiles < 1) {
        distStr = distanceKmOrMiles.format("%." + zeroToOneDigits + "f");
      } else if (distanceKmOrMiles < 10) {
        distStr = distanceKmOrMiles.format("%." + oneToTenDigits + "f");
      } else if (distanceKmOrMiles < 100) {
        distStr = distanceKmOrMiles.format("%." + tenToHundredDigits + "f");
      } else {
        distStr = distanceKmOrMiles.format("%." + hundredOnwardsDigits + "f");
      }
    } else {
      if (zeroToOneDigits == 3) {
        distStr = ZERO_DISTANCE3;
      } else if (zeroToOneDigits == 2) {
        distStr = ZERO_DISTANCE2;
      } else if (zeroToOneDigits == 1) {
        distStr = ZERO_DISTANCE1;
      } else {
        distStr = ZERO_DISTANCE;
      }
    }
    return distStr;
  }

  function setDeviceSettingsDependentVariables() {
    if (Sys.getDeviceSettings().distanceUnits == System.UNIT_METRIC) {
      kmOrMileInMeters = 1000;
    } else {
      kmOrMileInMeters = 1610;
    }
  }

  function getDevicePartNumber() {
    var deviceSettings = Sys.getDeviceSettings();
    // device part numbers come from ${SDKROOT}/bin/devices.xml
    var partNumber = deviceSettings.partNumber;
    return partNumber;
  }

  function getValueFont(dc, lapDistanceString) {
    var height = dc.getHeight();
    var width = dc.getWidth();
    var valueFont = Gfx.FONT_NUMBER_THAI_HOT;
    var valueFontHeight = Gfx.getFontHeight(valueFont);
    var labelFontHeight = Gfx.getFontHeight(labelFont);
    if (hideLabel == true) {
      labelFontHeight = 0;
    }
    var lastValueFontHeight = Gfx.getFontHeight(lastValueFont);
    if (showLastLap != true) {
      lastValueFontHeight = 0;
    }
    var heightOversizeValue = 100; //For 15% oversize enter 115
    var widthOversizeValue = 100; //For 20% oversize enter 120

    if (overrideSizing == true) {
      //writeDebug("getValueFont - overrideSizing = " + overrideSizing);
      heightOversizeValue = App.Properties.getValue("heightoversizeoverride");
      //writeDebug("getValueFont - heightoversizeoverride = " + heightOversizeValue);
      widthOversizeValue = App.Properties.getValue("widthoversizeoverride");
      //writeDebug("getValueFont - widthoversizeoverride = " + widthOversizeValue);
    }

    //writeDebug("getValueFont - screen height = " + height);
    //writeDebug("getValueFont - screen width = " + width);
    //writeDebug("getValueFont - initial value font before height check = " + valueFont);
    //writeDebug("getValueFont - initial combined font height = " + (valueFontHeight + labelFontHeight + lastValueFontHeight));
    if (
      valueFontHeight + labelFontHeight + lastValueFontHeight >
      height * (heightOversizeValue / 100)
    ) {
      while (
        valueFontHeight + labelFontHeight + lastValueFontHeight >
          height * (heightOversizeValue / 100) &&
        valueFont >= 1
      ) {
        valueFont = valueFont - 1;
        valueFontHeight = Gfx.getFontHeight(valueFont as Gfx.FontType);
      }
      //writeDebug("getValueFont - screen height " + (height * (heightOversizeValue / 100)) + " incl. " + (heightOversizeValue / 100) +  " oversize factor to small for " + (valueFontHeight + labelFontHeight + lastValueFontHeight));
    }
    //writeDebug("getValueFont - combined font height after height check = " + (valueFontHeight + labelFontHeight + lastValueFontHeight));
    //writeDebug("getValueFont - value font after height check = " + valueFont);

    var valueFontWidth = dc.getTextWidthInPixels(lapDistanceString, valueFont);
    valueFontWidth = valueFontWidth * (widthOversizeValue / 100);
    //writeDebug("getValueFont - value font width before width check = " + valueFontWidth);
    if (
      showLastLap != true or
      valueFontWidth > width * (widthOversizeValue / 100)
    ) {
      while (
        valueFontWidth > width * (widthOversizeValue / 100) &&
        valueFont >= 1
      ) {
        valueFont = valueFont - 1;
        valueFontWidth = dc.getTextWidthInPixels(lapDistanceString, valueFont);
        valueFontWidth = valueFontWidth * (widthOversizeValue / 100);
      }
      //writeDebug("getValueFont - screen width " + (width * (widthOversizeValue / 100)) + " incl. " + (widthOversizeValue  / 100) +  " oversize factor to small for " + valueFontWidth);
    }
    //writeDebug("getValueFont - value font width after width check = " + valueFontWidth);
    //writeDebug("getValueFont - value font after width check = " + valueFont);

    //writeDebug("getValueFont - valueFont = " + valueFont);
    //writeDebug("getValueFont - combinedFontHeight = " + (valueFontHeight + labelFontHeight + lastValueFontHeight) + " and width = " + valueFontWidth);
    return valueFont;
  }

  function writeDebug(message) {
    try {
      if (debugMode == true) {
        Sys.println(message);
      }
    } catch (ex) {
      Sys.println("Failed to write debug message!");
    }
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
