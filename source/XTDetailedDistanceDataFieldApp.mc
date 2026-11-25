using Toybox.Application as App;

class XTDetailedDistanceDataFieldApp extends App.AppBase {
  hidden var view;

  function initialize() {
    AppBase.initialize();
  }

  //! Return the initial view of your application here
  function getInitialView() {
    view = new XTDetailedDistanceDataFieldView();
    return [ view ];
  }

  // The user changed a setting: let the view reload them.
  function onSettingsChanged() {
    if (view != null) {
      view.onSettingsChanged();
    }
  }
}
