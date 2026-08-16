using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Activity;
using Toybox.Math;
using Toybox.Application;
using Toybox.Sensor;

class DataProvider {

    // Returns [label, value, unit] for a given data field type
    // value is "NoGPS" when GPS is required but unavailable
    static function getFieldData(dfType, posInfo, hasGps, qnhHpa) {
        switch (dfType) {
            case DF_GPS_ALT:
                return getGpsAlt(posInfo, hasGps);
            case DF_QNH_ALT:
                return getQnhAlt(posInfo, hasGps, qnhHpa);
            case DF_GROUND_SPEED:
                return getGroundSpeed(posInfo, hasGps);
            case DF_GPS_TRACK:
                return getGpsTrack(posInfo, hasGps);
            case DF_V_SPEED:
                return getVSpeed();
            case DF_LAT:
                return getLat(posInfo, hasGps);
            case DF_LON:
                return getLon(posInfo, hasGps);
            case DF_UTC_TIME:
                return getUtcTime();
            case DF_LOCAL_TIME:
                return getLocalTime();
            case DF_BATTERY:
                return getBattery();
            case DF_PRESSURE:
                return getPressure();
            case DF_GPS_ACCURACY:
                return getGpsAccuracy(posInfo, hasGps);
            case DF_OAT:
                return getOat();
            case DF_DENSITY_ALT:
                return getDensityAlt(posInfo, hasGps, qnhHpa);
        }
        return ["---", "---", ""];
    }

    // Short label for a data field
    static function getLabel(dfType) {
        switch (dfType) {
            case DF_GPS_ALT:      return "ALT GPS";
            case DF_QNH_ALT:      return "ALT QNH";
            case DF_GROUND_SPEED: return "GS";
            case DF_GPS_TRACK:    return "TRK";
            case DF_V_SPEED:      return "VS";
            case DF_LAT:          return "LAT";
            case DF_LON:          return "LON";
            case DF_UTC_TIME:     return "UTC";
            case DF_LOCAL_TIME:   return "LCL";
            case DF_BATTERY:      return "BATT";
            case DF_PRESSURE:     return "QFE";
            case DF_GPS_ACCURACY: return "GPS";
            case DF_OAT:          return "OAT";
            case DF_DENSITY_ALT:  return "DA";
        }
        return "?";
    }

    //--- Individual field implementations ---

    static function getGpsAlt(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.altitude == null) {
            return ["ALT GPS", "NoGPS", "ft"];
        }
        var altFt = (posInfo.altitude * 3.28084f).toNumber();
        return ["ALT GPS", altFt.toString(), "ft"];
    }

    static function getQnhAlt(posInfo, hasGps, qnhHpa) {
        // Try barometric pressure first
        var pressure = null;
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo has :ambientPressure && actInfo.ambientPressure != null) {
            pressure = actInfo.ambientPressure / 100.0f; // Pa -> hPa
        }
        if (pressure != null && pressure > 100.0f && qnhHpa > 0) {
            // ISA formula: h(ft) = 145366.45 * (1 - (P/QNH)^0.190284)
            var ratio = pressure / qnhHpa.toFloat();
            var altFt = (145366.45f * (1.0f - Math.pow(ratio, 0.190284f))).toNumber();
            return ["ALT QNH", altFt.toString(), "ft"];
        }
        // Fallback: GPS alt + QNH correction
        if (!hasGps || posInfo == null || posInfo.altitude == null) {
            return ["ALT QNH", "NoGPS", "ft"];
        }
        var gpsAltFt = posInfo.altitude * 3.28084f;
        var correction = (qnhHpa.toFloat() - 1013.25f) * 30.0f;
        var qnhAlt = (gpsAltFt + correction).toNumber();
        return ["ALT QNH", qnhAlt.toString(), "ft"];
    }

    static function getGroundSpeed(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.speed == null) {
            return ["GS", "NoGPS", "kt"];
        }
        // m/s -> knots (1 kt = 0.514444 m/s)
        var kts = (posInfo.speed / 0.514444f).toNumber();
        return ["GS", kts.toString(), "kt"];
    }

    static function getGpsTrack(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.heading == null) {
            return ["TRK", "NoGPS", "\u00B0"];
        }
        var deg = Math.toDegrees(posInfo.heading).toNumber();
        if (deg < 0) { deg += 360; }
        return ["TRK", deg.format("%03d"), "\u00B0"];
    }

    static function getVSpeed() {
        var actInfo = Activity.getActivityInfo();
        if (actInfo == null) {
            return ["VS", "---", "ft/m"];
        }
        // Try altitude change rate if available
        if (actInfo has :currentSpeed && actInfo.currentSpeed != null) {
            // Many devices expose vertical speed via Activity
        }
        // Use altitude from activity for vspeed if available
        return ["VS", "---", "ft/m"];
    }

    static function getLat(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.position == null) {
            return ["LAT", "NoGPS", ""];
        }
        var coords = posInfo.position.toDegrees();
        var lat = coords[0];
        var ns = (lat >= 0) ? "N" : "S";
        if (lat < 0) { lat = -lat; }
        var deg = lat.toNumber();
        var minRaw = (lat - deg) * 60.0f;
        var min = minRaw.format("%06.3f");
        return ["LAT", ns + deg.toString() + "\u00B0" + min, ""];
    }

    static function getLon(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.position == null) {
            return ["LON", "NoGPS", ""];
        }
        var coords = posInfo.position.toDegrees();
        var lon = coords[1];
        var ew = (lon >= 0) ? "E" : "W";
        if (lon < 0) { lon = -lon; }
        var deg = lon.toNumber();
        var minRaw = (lon - deg) * 60.0f;
        var min = minRaw.format("%06.3f");
        return ["LON", ew + deg.format("%03d") + "\u00B0" + min, ""];
    }

    static function getUtcTime() {
        var now = Gregorian.utcInfo(Time.now(), Gregorian.FORMAT_SHORT);
        var str = now.hour.format("%02d") + ":" + now.min.format("%02d") + ":" + now.sec.format("%02d");
        return ["UTC", str, ""];
    }

    static function getLocalTime() {
        var now = Gregorian.info(Time.now(), Gregorian.FORMAT_SHORT);
        var str = now.hour.format("%02d") + ":" + now.min.format("%02d");
        return ["LCL", str, ""];
    }

    static function getBattery() {
        var stats = System.getSystemStats();
        var pct = stats.battery.toNumber();
        return ["BATT", pct.toString(), "%"];
    }

    static function getPressure() {
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo has :ambientPressure && actInfo.ambientPressure != null) {
            var hpa = (actInfo.ambientPressure / 100.0f);
            return ["QFE", hpa.format("%.1f"), "hPa"];
        }
        return ["QFE", "---", "hPa"];
    }

    static function getGpsAccuracy(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.accuracy == null) {
            return ["GPS", "NoGPS", ""];
        }
        var acc = posInfo.accuracy;
        var txt = "---";
        switch (acc) {
            case Position.QUALITY_NOT_AVAILABLE: txt = "N/A"; break;
            case Position.QUALITY_LAST_KNOWN:    txt = "Last"; break;
            case Position.QUALITY_POOR:          txt = "Poor"; break;
            case Position.QUALITY_USABLE:        txt = "Ok"; break;
            case Position.QUALITY_GOOD:          txt = "Good"; break;
        }
        return ["GPS", txt, ""];
    }

    static function getOat() {
        var sensorInfo = Sensor.getInfo();
        if (sensorInfo != null && sensorInfo has :temperature && sensorInfo.temperature != null) {
            var t = sensorInfo.temperature.toNumber();
            return ["OAT", t.toString(), "\u00B0C"];
        }
        return ["OAT", "---", "\u00B0C"];
    }

    static function getDensityAlt(posInfo, hasGps, qnhHpa) {
        // DA = PA + (120 * (OAT - ISA_temp))
        // PA from pressure, ISA_temp = 15 - 2*PA/1000
        var pressure = null;
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo has :ambientPressure && actInfo.ambientPressure != null) {
            pressure = actInfo.ambientPressure / 100.0f;
        }
        var sensorInfo = Sensor.getInfo();
        var oat = null;
        if (sensorInfo != null && sensorInfo has :temperature && sensorInfo.temperature != null) {
            oat = sensorInfo.temperature.toFloat();
        }
        if (pressure != null && pressure > 100.0f && oat != null) {
            // Pressure altitude (ft) with standard QNH 1013.25
            var paFt = 145366.45f * (1.0f - Math.pow(pressure / 1013.25f, 0.190284f));
            var isaTemp = 15.0f - 0.001981f * paFt; // ~2°C/1000ft
            var da = (paFt + 120.0f * (oat - isaTemp)).toNumber();
            return ["DA", da.toString(), "ft"];
        }
        if (!hasGps) {
            return ["DA", "NoGPS", "ft"];
        }
        return ["DA", "---", "ft"];
    }
}
