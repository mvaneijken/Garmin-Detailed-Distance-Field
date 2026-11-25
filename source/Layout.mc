using Toybox.Graphics as Gfx;
using Toybox.Math;

// Fonts and positions of the three text lines (label, lap distance, previous lap).
// update() only needs the numbers a draw context provides (width, height, text width), so unit tests
// can call it with a fake draw context.
class Layout {
  const labelFont = Gfx.FONT_SYSTEM_XTINY;
  const lastValueFont = Gfx.FONT_XTINY;

  var valueFont = Gfx.FONT_NUMBER_THAI_HOT;
  var labelPosY = 0;
  var valuePosY = 0;
  var lastValuePosY = 0;
  var startPosX = 0;
  var justification = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;

  // The result stays valid until the size, the obscurity or the settings change (the view calls
  // invalidate() for those) or the value text changes length.
  hidden var valid = false;
  hidden var textLength = -1;

  function initialize() {}

  function invalidate() {
    valid = false;
  }

  function isValid(valueTextLength) {
    return valid && valueTextLength == textLength;
  }

  // obscurity: DataField.getObscurityFlags(). valueText: the string drawn in the value font.
  function update(dc, obscurity, settings, valueText) {
    valid = true;
    textLength = valueText.length();
    var width = dc.getWidth();
    var height = dc.getHeight();
    var hideLabel = settings.hideLabel;
    var showLastLap = settings.showLastLap;

    justification = getJustification(obscurity);
    startPosX = getStartPosX(obscurity, width);

    var labelFontHeight = Gfx.getFontHeight(labelFont);
    if (hideLabel == true) {
      labelFontHeight = 0;
    }
    var lastValueFontHeight = Gfx.getFontHeight(lastValueFont);

    if (isSingleFieldLayout(obscurity)) {
      valueFont = Gfx.FONT_NUMBER_THAI_HOT;
      var valueFontHeight = Gfx.getFontHeight(valueFont);

      valuePosY = height / 2;
      labelPosY = valuePosY - (labelFontHeight / 2 + valueFontHeight / 2);
      lastValuePosY =
        valuePosY + (valueFontHeight / 2 + lastValueFontHeight / 2);
    } else {
      valueFont = getValueFont(
        dc,
        settings,
        valueText,
        labelFontHeight
      );
      var valueFontHeight = Gfx.getFontHeight(valueFont);

      if (hideLabel == false || obscurity == 7) {
        valuePosY = height / 2;
      } else {
        valuePosY = height / 3;
      }
      if (hideLabel == false) {
        labelPosY = valuePosY - (valueFontHeight / 2 + labelFontHeight / 2);
        if (labelPosY - labelFontHeight / 2 < 0 + labelFontHeight / 2) {
          labelPosY = 0 + labelFontHeight / 2;
        }
      }
      lastValuePosY =
        valuePosY + (valueFontHeight / 2 + lastValueFontHeight / 2);

      if (obscurity == 3 or obscurity == 6) {
        // Top left or top right
        lastValuePosY = height - lastValueFontHeight / 2;
        if (showLastLap != true) {
          lastValuePosY = 0;
        }
        valuePosY =
          lastValuePosY - (valueFontHeight / 2 + lastValueFontHeight / 2);
        labelPosY = valuePosY - (valueFontHeight / 2 + labelFontHeight / 2);
      }
      if (obscurity == 9 or obscurity == 12) {
        // Bottom left or bottom right
        labelPosY = 0 + labelFontHeight / 2;
        valuePosY = labelPosY + (valueFontHeight / 2 + labelFontHeight / 2);
        lastValuePosY =
          valuePosY + (valueFontHeight / 2 + lastValueFontHeight / 2);
      }
      if (hideLabel == true && obscurity == 7) {
        // Bottom center, top
        lastValuePosY = height - lastValueFontHeight / 2;
        if (showLastLap != true) {
          lastValuePosY = 0;
        }
        valuePosY =
          lastValuePosY - (valueFontHeight / 2 + lastValueFontHeight / 2);
      }
    }
  }

  // All four sides obscured (the flags are 1, 2, 4 and 8) means the field fills the screen.
  function isSingleFieldLayout(obscurity) {
    return obscurity == 15;
  }

  function getJustification(obscurity) {
    if (obscurity == 12 or obscurity == 6) {
      return Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
    } else if (obscurity == 3 or obscurity == 9) {
      return Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
    }
    return Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
  }

  function getStartPosX(obscurity, width) {
    var margin = Math.round((width / 100) * 2);
    if (obscurity == 12 or obscurity == 6) {
      return 0 + margin;
    } else if (obscurity == 3 or obscurity == 9) {
      return width - margin;
    }
    return width / 2;
  }

  // Steps down from the largest number font until the text fits the height, then the width.
  // The correction factors use integer division (a Number divided by 100), as the field always did:
  // 100 to 199 act as 100 %, below 100 as 0 %. Keep it that way until a decision on the fix.
  function getValueFont(dc, settings, valueText, labelFontHeight) {
    var height = dc.getHeight();
    var width = dc.getWidth();
    var font = Gfx.FONT_NUMBER_THAI_HOT;
    var fontHeight = Gfx.getFontHeight(font);
    var lastValueFontHeight = Gfx.getFontHeight(lastValueFont);
    if (settings.showLastLap != true) {
      lastValueFontHeight = 0;
    }
    var heightOversizeValue = 100;
    var widthOversizeValue = 100;

    if (settings.overrideSizing == true) {
      heightOversizeValue = settings.heightOversize;
      widthOversizeValue = settings.widthOversize;
    }

    while (
      fontHeight + labelFontHeight + lastValueFontHeight >
        height * (heightOversizeValue / 100) &&
      font >= 1
    ) {
      font = font - 1;
      fontHeight = Gfx.getFontHeight(font as Gfx.FontType);
    }

    var valueFontWidth = dc.getTextWidthInPixels(valueText, font);
    valueFontWidth = valueFontWidth * (widthOversizeValue / 100);
    while (valueFontWidth > width * (widthOversizeValue / 100) && font >= 1) {
      font = font - 1;
      valueFontWidth = dc.getTextWidthInPixels(valueText, font);
      valueFontWidth = valueFontWidth * (widthOversizeValue / 100);
    }
    return font;
  }
}
