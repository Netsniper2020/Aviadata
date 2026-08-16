using Toybox.Application;
using Toybox.WatchUi as Ui;
using Toybox.Position;
using Toybox.System;

// Data field type constants
enum {
    DF_GPS_ALT = 0,
    DF_QNH_ALT = 1,
    DF_GROUND_SPEED = 2,
    DF_GPS_TRACK = 3,
    DF_V_SPEED = 4,
    DF_LAT = 5,
    DF_LON = 6,
    DF_UTC_TIME = 7,
    DF_LOCAL_TIME = 8,
    DF_BATTERY = 9,
    DF_PRESSURE = 10,
    DF_GPS_ACCURACY = 11,
    DF_OAT = 12,
    DF_DENSITY_ALT = 13,
    DF_COUNT = 14
}

enum {
    POS_NA = 0,
    POS_TOP = 17,
    POS_BOT = 18
}

enum {
    QUAD_HG = 0,
    QUAD_HD = 1,
    QUAD_BG = 2,
    QUAD_BD = 3
}

var PROP_KEYS = [
    "posGpsAlt",
    "posQnhAlt",
    "posGroundSpeed",
    "posGpsTrack",
    "posVSpeed",
    "posLat",
    "posLon",
    "posUtcTime",
    "posLocalTime",
    "posBattery",
    "posPressure",
    "posGpsAccuracy",
    "posOat",
    "posDensityAlt"
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
