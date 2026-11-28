using Toybox.Graphics as Gfx;
using Toybox.Test;

// Roadmap 6.2 and 6.3: the text colour setting and the halo. The halo is T1 and above (the t1 annotation).

// The text colour: Auto keeps today's behaviour (white on a black background, black otherwise).
(:test, :t1)
function testTextColorAutoFollowsTheBackground(logger) {
  Test.assertEqual(TextStyle.textColor(0, Gfx.COLOR_BLACK), Gfx.COLOR_WHITE);
  Test.assertEqual(TextStyle.textColor(0, Gfx.COLOR_WHITE), Gfx.COLOR_BLACK);
  return true;
}

(:test, :t1)
function testTextColorBlackAndWhiteOverrideTheBackground(logger) {
  Test.assertEqualMessage(TextStyle.textColor(1, Gfx.COLOR_BLACK), Gfx.COLOR_BLACK, "black on a map page");
  Test.assertEqualMessage(TextStyle.textColor(2, Gfx.COLOR_WHITE), Gfx.COLOR_WHITE, "white text");
  return true;
}

// A draw context that records what is drawn: [x, y, text, color] per drawText.
(:test, :t1)
class RecordingTextDc {
  hidden var color = 0;
  var texts = [];

  function setColor(foreground, background) {
    color = foreground;
  }

  function drawText(x, y, font, text, justification) {
    texts.add([x, y, text, color]);
  }
}

// The halo is the text repeated one pixel away in the opposite colour; the caller draws the text on top.
(:test, :t1)
function testHaloDrawsTheTextAroundItInTheOppositeColor(logger) {
  var dc = new RecordingTextDc();
  TextStyle.drawHalo(dc, 100, 50, Gfx.FONT_XTINY, "1.500", Gfx.TEXT_JUSTIFY_CENTER, Gfx.COLOR_WHITE);
  Test.assertEqualMessage(dc.texts.size(), 4, "four offsets");
  for (var index = 0; index < 4; index += 1) {
    Test.assertEqual(dc.texts[index][2], "1.500");
    Test.assertEqualMessage(dc.texts[index][3], Gfx.COLOR_BLACK, "black halo for white text");
    Test.assertMessage(
      (dc.texts[index][0] - 100).abs() == 1 && (dc.texts[index][1] - 50).abs() == 1,
      "one pixel diagonally"
    );
  }
  Test.assertMessage(dc.texts[0][0] != dc.texts[1][0] || dc.texts[0][1] != dc.texts[1][1], "four different offsets");
  return true;
}

(:test, :t1)
function testHaloOfBlackTextIsWhite(logger) {
  var dc = new RecordingTextDc();
  TextStyle.drawHalo(dc, 10, 10, Gfx.FONT_XTINY, "5:00", Gfx.TEXT_JUSTIFY_LEFT, Gfx.COLOR_BLACK);
  Test.assertEqual(dc.texts[0][3], Gfx.COLOR_WHITE);
  return true;
}

// One line of the field: the halo first, then the text on top in the colour of the setting.
(:test, :t1)
function testDrawLineWithAndWithoutHalo(logger) {
  var layout = new Layout();
  layout.startPosX = 100;
  layout.justification = Gfx.TEXT_JUSTIFY_CENTER;
  var settings = new Settings();
  settings.textColor = 1;
  var dc = new RecordingTextDc();
  TextStyle.drawLine(dc, layout, 50, Gfx.FONT_XTINY, "1.500", settings, Gfx.COLOR_BLACK);
  Test.assertEqualMessage(dc.texts.size(), 1, "no halo by default");
  Test.assertEqualMessage(dc.texts[0][3], Gfx.COLOR_BLACK, "the setting wins over the white of a black background");
  settings.halo = true;
  dc = new RecordingTextDc();
  TextStyle.drawLine(dc, layout, 50, Gfx.FONT_XTINY, "1.500", settings, Gfx.COLOR_BLACK);
  Test.assertEqualMessage(dc.texts.size(), 5, "four halo texts and the text");
  Test.assertEqual(dc.texts[0][3], Gfx.COLOR_WHITE);
  Test.assertEqualMessage(dc.texts[4][3], Gfx.COLOR_BLACK, "the text itself is last, in its own colour");
  Test.assertEqual(dc.texts[4][0], 100);
  return true;
}

// The probe line of the background (roadmap 6.1) only exists in the probe build.
(:test, :probe)
function testProbeBackgroundLine(logger) {
  Test.assertEqualMessage(
    Probe.backgroundLine(123456, Gfx.COLOR_BLACK, 7),
    "P,bg,123456," + Gfx.COLOR_BLACK + ",7,0,0,0",
    "the line the script parses: color in the timer column, obscurity in the distance column"
  );
  return true;
}
