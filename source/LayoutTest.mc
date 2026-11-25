using Toybox.Graphics as Gfx;
using Toybox.Test;

// A draw context that only answers what Layout asks: size and text width. A character is
// (font + 1) * 2 pixels wide, so a larger font needs more room, like on a device.
(:test)
class FakeDc {
  hidden var screenWidth;
  hidden var screenHeight;

  function initialize(width, height) {
    screenWidth = width;
    screenHeight = height;
  }

  function getWidth() {
    return screenWidth;
  }

  function getHeight() {
    return screenHeight;
  }

  function getTextWidthInPixels(text, font) {
    return text.length() * (font + 1) * 2;
  }
}

(:test)
function testSingleFieldIsCentered(logger) {
  var layout = new Layout();
  var settings = new Settings();
  settings.hideLabel = false;
  settings.showLastLap = true;
  layout.update(new FakeDc(240, 240), 15, settings, "1.500");
  Test.assertEqualMessage(layout.valueFont, Gfx.FONT_NUMBER_THAI_HOT, "single field uses the largest font");
  Test.assertEqual(layout.valuePosY, 120);
  Test.assertEqual(layout.startPosX, 120);
  Test.assertEqual(layout.justification, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
  Test.assertMessage(layout.labelPosY < layout.valuePosY, "the label is above the value");
  Test.assertMessage(layout.lastValuePosY > layout.valuePosY, "the previous lap is below the value");
  return true;
}

// The justification and the start position follow the obscurity flags (left, right, centre).
(:test)
function testJustificationAndStartPosition(logger) {
  var layout = new Layout();
  var settings = new Settings();
  var dc = new FakeDc(200, 100);
  // 12 and 6: left aligned with a margin of 2 % of the width
  layout.update(dc, 12, settings, "1.5");
  Test.assertEqual(layout.justification, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
  Test.assertEqual(layout.startPosX, 4);
  layout.update(dc, 6, settings, "1.5");
  Test.assertEqual(layout.justification, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
  // 3 and 9: right aligned
  layout.update(dc, 3, settings, "1.5");
  Test.assertEqual(layout.justification, Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
  Test.assertEqual(layout.startPosX, 196);
  layout.update(dc, 9, settings, "1.5");
  Test.assertEqual(layout.justification, Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
  // anything else: centred
  layout.update(dc, 0, settings, "1.5");
  Test.assertEqual(layout.justification, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
  Test.assertEqual(layout.startPosX, 100);
  return true;
}

// A longer text gets a smaller font (the font-fit loop), and the font never grows past the largest.
(:test)
function testFontShrinksForLongText(logger) {
  var layout = new Layout();
  var settings = new Settings();
  settings.hideLabel = true;
  settings.showLastLap = false;
  var dc = new FakeDc(200, 400);
  layout.update(dc, 7, settings, "1");
  var shortFont = layout.valueFont;
  layout.update(dc, 7, settings, "123456789.123");
  Test.assertMessage(layout.valueFont < shortFont, "a long text needs a smaller font");
  Test.assertMessage(shortFont <= Gfx.FONT_NUMBER_THAI_HOT, "never larger than the largest number font");
  return true;
}

// A hidden label gives the value more room, so the value is placed higher in the field.
(:test)
function testHiddenLabelMovesValueUp(logger) {
  var layout = new Layout();
  var settings = new Settings();
  settings.showLastLap = true;
  var dc = new FakeDc(200, 120);
  settings.hideLabel = false;
  layout.update(dc, 7, settings, "1.5");
  var withLabel = layout.valuePosY;
  settings.hideLabel = true;
  layout.update(dc, 7, settings, "1.5");
  Test.assertMessage(layout.valuePosY != withLabel, "the value moves when the label is hidden");
  return true;
}
