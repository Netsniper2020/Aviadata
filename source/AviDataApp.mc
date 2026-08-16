using Toybox.Application;
using Toybox.WatchUi as Ui;
using Toybox.Position;
using Toybox.System;

// Data field type constants — match settings list values
enum {
    DF_NONE = 0,
    DF_GPS_ALT = 1,
    DF_QNH_ALT = 2,
    DF_GPS_QNH_ALT = 3,
    DF_GROUND_SPEED = 4,
    DF_GPS_TRACK = 5,
    DF_V_SPEED = 6,
    DF_LAT = 7,
    DF_LON = 8,
    DF_UTC_TIME = 9,
    DF_LOCAL_TIME = 10,
    DF_BATTERY = 11,
    DF_PRESSURE = 12,
    DF_GPS_ACCURACY = 13,
    DF_OAT = 14,
    DF_DENSITY_ALT = 15
}

// Slot property keys ordered: P1HG..P4BD, TOP, BOT
var SLOT_KEYS = [
    "slotP1HG", "slotP1HD", "slotP1BG", "slotP1BD",
    "slotP2HG", "slotP2HD", "slotP2BG", "slotP2BD",
    "slotP3HG", "slotP3HD", "slotP3BG", "slotP3BD",
    "slotP4HG", "slotP4HD", "slotP4BG", "slotP4BD",
    "slotTOP", "slotBOT"
];

class AviDataApp extends Application.AppBase {
    var posInfo = null;
    var hasGps = false;
    var _view = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition) as Method(info as Position.Info) as Void);
    }

    function onStop(state) {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition) as Method(info as Position.Info) as Void);
    }

    function onPosition(info as Position.Info) as Void {
        posInfo = info;
        if (info != null && info.accuracy != null && info.accuracy >= Position.QUALITY_LAST_KNOWN) {
            hasGps = true;
        } else {
            hasGps = false;
        }
        Ui.requestUpdate();
    }

    function getInitialView() {
        _view = new PageView();
        return [_view, new PageDelegate(_view)];
    }

    function onSettingsChanged() {
        if (_view != null) {
            _view.loadSettings();
        }
        Ui.requestUpdate();
    }
}
