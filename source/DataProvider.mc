using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Activity;
using Toybox.Math;
using Toybox.Application;
using Toybox.Sensor;

class DataProvider {

    static function getFieldData(dfType, posInfo, hasGps, qnhHpa, geoidM, gpsStale) {
        switch (dfType) {
            case DF_GPS_ALT:      return getGpsAlt(posInfo, hasGps, geoidM, gpsStale);
            case DF_QNH_ALT:      return getQnhAlt(posInfo, hasGps, qnhHpa, geoidM, gpsStale);
            case DF_GPS_QNH_ALT:  return getGpsQnhAlt(posInfo, hasGps, qnhHpa, geoidM, gpsStale);
            case DF_GROUND_SPEED: return getGroundSpeed(posInfo, hasGps, gpsStale);
            case DF_GPS_TRACK:    return getGpsTrack(posInfo, hasGps, gpsStale);
            case DF_V_SPEED:      return getVSpeed(gpsStale);
            case DF_LAT:          return getLat(posInfo, hasGps);
            case DF_LON:          return getLon(posInfo, hasGps);
            case DF_UTC_TIME:     return getUtcTime();
            case DF_LOCAL_TIME:   return getLocalTime();
            case DF_BATTERY:      return getBattery();
            case DF_PRESSURE:     return getPressure();
            case DF_GPS_ACCURACY: return getGpsAccuracy(posInfo, hasGps);
            case DF_OAT:          return getOat();
            case DF_DENSITY_ALT:  return getDensityAlt(posInfo, hasGps, qnhHpa);
            default:              return ["---", "---", ""];
        }
    }

    static function getGpsAltMsl(posInfo, hasGps, geoidM) {
        if (!hasGps || posInfo == null || posInfo.altitude == null) { return null; }
        return ((posInfo.altitude - geoidM.toFloat()) * 3.28084f).toNumber();
    }

    static function getGpsAlt(posInfo, hasGps, geoidM, gpsStale) {
        if (!hasGps) { return ["ALT GPS", "NoGPS", "ft"]; }
        if (gpsStale) { return ["ALT GPS", "- - -", "ft"]; }
        var altFt = getGpsAltMsl(posInfo, hasGps, geoidM);
        if (altFt == null) { return ["ALT GPS", "- - -", "ft"]; }
        return ["ALT GPS", altFt.toString(), "ft"];
    }

    static function getQnhAlt(posInfo, hasGps, qnhHpa, geoidM, gpsStale) {
        // Barometric pressure path (not affected by GPS staleness)
        var pressure = null;
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo has :ambientPressure && actInfo.ambientPressure != null) {
            pressure = actInfo.ambientPressure / 100.0f;
        }
        if (pressure != null && pressure > 100.0f && qnhHpa > 0) {
            var ratio = pressure / qnhHpa.toFloat();
            var altFt = (145366.45f * (1.0f - Math.pow(ratio, 0.190284f))).toNumber();
            return ["ALT QNH", altFt.toString(), "ft"];
        }
        // GPS fallback
        if (!hasGps) { return ["ALT QNH", "NoGPS", "ft"]; }
        if (gpsStale) { return ["ALT QNH", "- - -", "ft"]; }
        var gpsAltFt = getGpsAltMsl(posInfo, hasGps, geoidM);
        if (gpsAltFt == null) { return ["ALT QNH", "- - -", "ft"]; }
        var correction = (qnhHpa.toFloat() - 1013.25f) * 30.0f;
        return ["ALT QNH", (gpsAltFt + correction).toNumber().toString(), "ft"];
    }

    static function getGpsQnhAlt(posInfo, hasGps, qnhHpa, geoidM, gpsStale) {
        var gpsData = getGpsAlt(posInfo, hasGps, geoidM, gpsStale);
        var qnhData = getQnhAlt(posInfo, hasGps, qnhHpa, geoidM, gpsStale);
        return ["GPS", gpsData[1], "QNH", qnhData[1], "ft"];
    }

    static function getGroundSpeed(posInfo, hasGps, gpsStale) {
        if (!hasGps) { return ["GS", "NoGPS", "kt"]; }
        if (gpsStale || posInfo == null || posInfo.speed == null) { return ["GS", "- - -", "kt"]; }
        var kts = (posInfo.speed / 0.514444f).toNumber();
        return ["GS", kts.toString(), "kt"];
    }

    static function getGpsTrack(posInfo, hasGps, gpsStale) {
        if (!hasGps) { return ["TRK", "NoGPS", "\u00B0"]; }
        if (gpsStale || posInfo == null || posInfo.heading == null) { return ["TRK", "- - -", "\u00B0"]; }
        var deg = Math.toDegrees(posInfo.heading).toNumber();
        if (deg < 0) { deg += 360; }
        return ["TRK", deg.format("%03d"), "\u00B0"];
    }

    static function getVSpeed(gpsStale) {
        var app = Application.getApp();
        if (!app.hasGps) { return ["VS", "NoGPS", "ft/m"]; }
        if (gpsStale || !app.vSpeedValid) { return ["VS", "- - -", "ft/m"]; }
        var vs = app.vSpeedFpm.toNumber();
        var sign = "";
        if (vs > 0) { sign = "+"; }
        return ["VS", sign + vs.toString(), "ft/m"];
    }

    static function getLat(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.position == null) { return ["LAT", "NoGPS", ""]; }
        var coords = posInfo.position.toDegrees();
        var lat = coords[0];
        var ns = (lat >= 0) ? "N" : "S";
        if (lat < 0) { lat = -lat; }
        var deg = lat.toNumber();
        var minRaw = (lat - deg) * 60.0f;
        return ["LAT", ns + deg.toString() + "\u00B0" + minRaw.format("%06.3f"), ""];
    }

    static function getLon(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.position == null) { return ["LON", "NoGPS", ""]; }
        var coords = posInfo.position.toDegrees();
        var lon = coords[1];
        var ew = (lon >= 0) ? "E" : "W";
        if (lon < 0) { lon = -lon; }
        var deg = lon.toNumber();
        var minRaw = (lon - deg) * 60.0f;
        return ["LON", ew + deg.format("%03d") + "\u00B0" + minRaw.format("%06.3f"), ""];
    }

    static function getUtcTime() {
        var now = Gregorian.utcInfo(Time.now(), Time.FORMAT_MEDIUM);
        return ["UTC", now.hour.format("%02d") + ":" + now.min.format("%02d") + ":" + now.sec.format("%02d"), "Z"];
    }

    static function getLocalTime() {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return ["LCL", now.hour.format("%02d") + ":" + now.min.format("%02d") + ":" + now.sec.format("%02d"), ""];
    }

    static function getBattery() {
        var stats = System.getSystemStats();
        return ["BATT", stats.battery.toNumber().toString(), "%"];
    }

    static function getPressure() {
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo has :ambientPressure && actInfo.ambientPressure != null) {
            return ["QFE", (actInfo.ambientPressure / 100.0f).format("%.1f"), "hPa"];
        }
        return ["QFE", "---", "hPa"];
    }

    static function getGpsAccuracy(posInfo, hasGps) {
        if (!hasGps || posInfo == null || posInfo.accuracy == null) { return ["GPS", "NoGPS", ""]; }
        var txt = "---";
        switch (posInfo.accuracy) {
            case Position.QUALITY_NOT_AVAILABLE: txt = "N/A"; break;
            case Position.QUALITY_LAST_KNOWN:    txt = "Last"; break;
            case Position.QUALITY_POOR:          txt = "Poor"; break;
            case Position.QUALITY_USABLE:        txt = "Ok"; break;
            case Position.QUALITY_GOOD:          txt = "Good"; break;
        }
        return ["GPS", txt, ""];
    }

    static function getOat() {
        var si = Sensor.getInfo();
        if (si != null && si has :temperature && si.temperature != null) {
            return ["OAT", si.temperature.toNumber().toString(), "\u00B0C"];
        }
        return ["OAT", "---", "\u00B0C"];
    }

    static function getDensityAlt(posInfo, hasGps, qnhHpa) {
        var pressure = null;
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo has :ambientPressure && actInfo.ambientPressure != null) {
            pressure = actInfo.ambientPressure / 100.0f;
        }
        var si = Sensor.getInfo();
        var oat = null;
        if (si != null && si has :temperature && si.temperature != null) {
            oat = si.temperature.toFloat();
        }
        if (pressure != null && pressure > 100.0f && oat != null) {
            var paFt = 145366.45f * (1.0f - Math.pow(pressure / 1013.25f, 0.190284f));
            var isaTemp = 15.0f - 0.001981f * paFt;
            return ["DA", (paFt + 120.0f * (oat - isaTemp)).toNumber().toString(), "ft"];
        }
        if (!hasGps) { return ["DA", "NoGPS", "ft"]; }
        return ["DA", "---", "ft"];
    }
}
