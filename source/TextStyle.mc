using Toybox.Graphics as Gfx;

// The look of the text (roadmap 6.2 and 6.3), for the map pages of the newer watches where the field sits on
// a light map and the native fields use dark text with a light halo.
//
// The text colour setting: 0 Auto (white on a black data screen, black otherwise: what the field always
// did), 1 Black, 2 White. The halo is the text drawn again one pixel away in the opposite colour, behind the
// text: a Connect IQ field has no outline call. The halo costs four extra drawText calls per line, so it is T1
// and above (the t1 annotation); T0 devices keep Auto and no halo.
module TextStyle {
  (:t1)
  function textColor(mode, background) {
    if (mode == 1) {
      return Gfx.COLOR_BLACK;
    } else if (mode == 2) {
      return Gfx.COLOR_WHITE;
    }
    return background == Gfx.COLOR_BLACK ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
  }

  // Draws the halo of one line in the opposite colour, then sets the text colour again. The caller draws
  // the text itself after this call.
  (:t1)
  function drawHalo(dc, x, y, font, text, justification, color) {
    dc.setColor(color == Gfx.COLOR_WHITE ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    dc.drawText(x - 1, y - 1, font, text, justification);
    dc.drawText(x + 1, y - 1, font, text, justification);
    dc.drawText(x - 1, y + 1, font, text, justification);
    dc.drawText(x + 1, y + 1, font, text, justification);
    dc.setColor(color, Gfx.COLOR_TRANSPARENT);
  }

  // One line of text of the field: colour by the setting, the halo when it is on, then the text.
  (:t1)
  function drawLine(dc, layout, y, font, text, settings, background) {
    var color = textColor(settings.textColor, background);
    dc.setColor(color, Gfx.COLOR_TRANSPARENT);
    if (settings.halo) {
      drawHalo(dc, layout.startPosX, y, font, text, layout.justification, color);
    }
    dc.drawText(layout.startPosX, y, font, text, layout.justification);
  }

  // T0: the text colour is set once by the view (white on a black data screen, black otherwise).
  (:t0)
  function drawLine(dc, layout, y, font, text, settings, background) {
    dc.drawText(layout.startPosX, y, font, text, layout.justification);
  }
}