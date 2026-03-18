import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class XTDetailedDistanceDataFieldApp extends Application.AppBase {
  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {}

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {}

  //! Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    return [new XTDetailedDistanceDataFieldView()];
  }

  //! Return the settings view and delegate for the app
  //! @return Array Pair [View, Delegate]
  public function getSettingsView() as [Views] or
    [Views, InputDelegates] or
    Null {
    return [
      new XTDetailedDistanceDataFieldSettingsView(),
      new XTDetailedDistanceDataFieldSettingsDelegate(),
    ];
  }
}
