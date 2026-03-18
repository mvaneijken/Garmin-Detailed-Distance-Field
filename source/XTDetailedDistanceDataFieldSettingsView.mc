import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Initial view for the settings
class XTDetailedDistanceDataFieldSettingsView extends WatchUi.View {
  //! Constructor
  public function initialize() {
    View.initialize();
  }

  //! Update the view
  //! @param dc Device context
  public function onUpdate(dc as Dc) as Void {
    dc.clearClip();
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

    dc.drawText(
      dc.getWidth() / 2,
      dc.getHeight() / 2 - 30,
      Graphics.FONT_SMALL,
      "Press Menu \nfor settings",
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }
}

//! Handle opening the settings menu
class XTDetailedDistanceDataFieldSettingsDelegate extends WatchUi.BehaviorDelegate {
  //! Constructor
  public function initialize() {
    BehaviorDelegate.initialize();
  }

  //! Handle the menu event
  //! @return true if handled, false otherwise
  public function onMenu() as Boolean {
    var menu = new XTDetailedDistanceDataFieldSettingsMenu();
    var boolean = Storage.getValue(1) ? true : false;
    menu.addItem(
      new WatchUi.ToggleMenuItem(
        Rez.Strings.showLastLap_prop,
        null,
        1,
        boolean,
        null
      )
    );

    boolean = Storage.getValue(2) ? true : false;
    menu.addItem(
      new WatchUi.ToggleMenuItem(Rez.Strings.hideLabel, null, 2, boolean, null)
    );

    boolean = Storage.getValue(3) ? true : false;
    menu.addItem(
      new WatchUi.ToggleMenuItem("Settings3", null, 3, boolean, null)
    );

    boolean = Storage.getValue(4) ? true : false;
    menu.addItem(
      new WatchUi.ToggleMenuItem("Settings4", null, 4, boolean, null)
    );

    WatchUi.pushView(
      menu,
      new XTDetailedDistanceDataFieldSettingsMenuDelegate(),
      WatchUi.SLIDE_IMMEDIATE
    );
    return true;
  }
}
