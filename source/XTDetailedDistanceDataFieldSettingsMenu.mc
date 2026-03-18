//
// Copyright 2016-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! The settings menu
class XTDetailedDistanceDataFieldSettingsMenu extends WatchUi.Menu2 {
  //! Constructor
  public function initialize() {
    Menu2.initialize({ :title => "Settings" });
  }
}

//! Handles menu input and stores the menu data
class XTDetailedDistanceDataFieldSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
  //! Constructor
  public function initialize() {
    Menu2InputDelegate.initialize();
  }

  //! Handle a menu item selection
  //! @param menuItem The selected menu item
  public function onSelect(menuItem as MenuItem) as Void {
    var id = menuItem.getId();
    if (id instanceof Number && menuItem instanceof ToggleMenuItem) {
      Properties.setValue(id as Number, menuItem.isEnabled());
    }
  }
}

// class XTDetailedDistanceDataFieldSettingsMenuItemDecimals extends Ui.Menu2 {
//     var _callback;

//     function initialize(callback) {
//         Menu2.initialize();
//         _callback = callback; // Callback to send the selected value back
//     }

// function onLayout(dc) {
//     // Define the layout of the menu items
//     setLayout({
//         title: "Select a Value",
//         items: [
//             { name: "Value 0", value: 0 },
//             { name: "Value 1", value: 1 },
//             { name: "Value 2", value: 2 },
//             { name: "Value 3", value: 3 }
//         ]
//     });
// }

//     function onSelect(item) {
//         // Called when a user selects an item
//         var selectedValue = item.value;
//         _callback(selectedValue); // Pass the selected value back
//         Ui.popView(); // Return to the previous view
//     }
// }
