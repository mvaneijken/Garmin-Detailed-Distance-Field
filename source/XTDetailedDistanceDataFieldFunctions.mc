using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;

class Functions {

  // Display the value you computed here. This will be called
  // once a second when the data field is visible.

  hidden const ZERO_DISTANCE3 = "0.000";
  hidden const ZERO_DISTANCE2 = "0.00";
  hidden const ZERO_DISTANCE1 = "0.0";
  hidden const ZERO_DISTANCE = "0";


  function isSingleFieldLayout(DataField) {
    return (
      DataField.getObscurityFlags() ==
      (DataField.OBSCURE_TOP | DataField.OBSCURE_LEFT | DataField.OBSCURE_BOTTOM | DataField.OBSCURE_RIGHT)
    );
  }

  function getTextJustification(DataField) {
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

  function getTextJustificationLValue(DataField) {
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

  function getStartPosX(width,DataField) {
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

  function getShowLastLapProp() {
    var showLastLap_prop = App.Properties.getValue("showLastLap_prop");
    var showLastLap = false;
    if (null == showLastLap_prop) {
      showLastLap = false;
    } else {
      showLastLap = showLastLap_prop;
    }
    return showLastLap;
  }


  function setDistStr(distance,zeroToOneDigits,oneToTenDigits,tenToHundredDigits,hundredOnwardsDigits) {
    var distStr;
    var kmOrMileInMeters = Functions.setDeviceSettingsDependentVariables();
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
    var kmOrMileInMeters = 1610;
    if (Sys.getDeviceSettings().distanceUnits == System.UNIT_METRIC) {
      kmOrMileInMeters = 1000;
    }
    return kmOrMileInMeters;
  }

  // function getDevicePartNumber() {
  //   var deviceSettings = Sys.getDeviceSettings();
  //   // device part numbers come from ${SDKROOT}/bin/devices.xml
  //   var partNumber = deviceSettings.partNumber;
  //   return partNumber;
  // }

  function getValueFont(dc, lapDistanceString,hideLabel,showLastLap,labelFont,lastValueFont,overrideSizing, App) {
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
      var debugMode = App.Properties.getValue("debugmode");
      if (debugMode == true) {
        Sys.println(message);
      }
    } catch (ex) {
      Sys.println("Failed to write debug message!");
    }
  }


}