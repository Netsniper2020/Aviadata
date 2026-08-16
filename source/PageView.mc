using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Math;
using Toybox.Timer;

class PageView extends Ui.View {

    const MAX_PAGES = 4;

    var currentPage = 0;
    var totalPages = 1;

    // pageSlots[page][quad] = dfType (DF_NONE if empty)
    var pageSlots = null;
    var topSlot = 0;   // DF_NONE
    var botSlot = 0;

    var qnhHpa = 1013;
    var showTrackTop = true;

    var _timer = null;
    var _quadCenters = null;
    var _quadHalfW = 0;
    var _quadHalfH = 0;

    function initialize() {
        View.initialize();
        pageSlots = new [MAX_PAGES];
        for (var p = 0; p < MAX_PAGES; p++) {
            pageSlots[p] = [DF_NONE, DF_NONE, DF_NONE, DF_NONE];
        }
        loadSettings();
    }

    function onShow() {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        _timer.start(method(:onTick), 1000, true);
    }

    function onHide() {
        if (_timer != null) { _timer.stop(); }
    }

    function onTick() as Void {
        Ui.requestUpdate();
    }

    function loadSettings() {
        qnhHpa = readPropNum("qnhValue", 1013);
        showTrackTop = readPropBool("showTrackTop", true);

        // Read slot assignments: first 16 are page quadrants, 17=TOP, 18=BOT
        for (var i = 0; i < 16; i++) {
            var page = i / 4;
            var quad = i % 4;
            pageSlots[page][quad] = readPropNum(SLOT_KEYS[i], DF_NONE);
        }
        topSlot = readPropNum(SLOT_KEYS[16], DF_NONE);
        botSlot = readPropNum(SLOT_KEYS[17], DF_NONE);

        // Compute total active pages
        totalPages = 0;
        for (var p = 0; p < MAX_PAGES; p++) {
            for (var q = 0; q < 4; q++) {
                if (pageSlots[p][q] != DF_NONE) {
                    if (p + 1 > totalPages) { totalPages = p + 1; }
                    break;
                }
            }
        }
        if (totalPages < 1) { totalPages = 1; }
        if (currentPage >= totalPages) { currentPage = 0; }
    }

    function nextPage() {
        currentPage = (currentPage + 1) % totalPages;
        Ui.requestUpdate();
    }

    function prevPage() {
        currentPage = (currentPage - 1 + totalPages) % totalPages;
        Ui.requestUpdate();
    }

    // Returns dfType at tap coordinates, or DF_NONE
    function getFieldAtPosition(tapX, tapY) {
        if (_quadCenters == null) { return DF_NONE; }
        var slots = pageSlots[currentPage];
        for (var q = 0; q < 4; q++) {
            if (slots[q] == DF_NONE) { continue; }
            var qc = _quadCenters[q];
            var dx = tapX - qc[0];
            var dy = tapY - qc[1];
            if (dx < 0) { dx = -dx; }
            if (dy < 0) { dy = -dy; }
            if (dx < _quadHalfW && dy < _quadHalfH) {
                return slots[q];
            }
        }
        return DF_NONE;
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        var app = Application.getApp();
        var posInfo = app.posInfo;
        var hasGps = app.hasGps;

        var topBarY = 18;
        var botBarY = h - 18;

        var trackAreaH = showTrackTop ? 30 : 0;

        var quadTop = topBarY + 16 + trackAreaH;
        var quadBot = botBarY - 16;
        var quadMidY = (quadTop + quadBot) / 2;

        // --- Top persistent field ---
        if (topSlot != DF_NONE) {
            var td = DataProvider.getFieldData(topSlot, posInfo, hasGps, qnhHpa);
            var topStr = td[0] + " " + td[1];
            if (td.size() == 3 && !td[2].equals("")) {
                topStr = topStr + td[2];
            }
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, topBarY - 8, Gfx.FONT_XTINY, topStr, Gfx.TEXT_JUSTIFY_CENTER);
        }

        // --- GPS track indicator ---
        if (showTrackTop) {
            drawTrackIndicator(dc, cx, topBarY + 20, posInfo, hasGps);
        }

        // --- Dividers ---
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(cx - w / 3, quadMidY, cx + w / 3, quadMidY);
        dc.drawLine(cx, quadTop + 5, cx, quadBot - 5);

        // --- Quadrant centers ---
        _quadCenters = [
            [cx / 2 + 4,       (quadTop + quadMidY) / 2],
            [cx + cx / 2 - 4,  (quadTop + quadMidY) / 2],
            [cx / 2 + 4,       (quadMidY + quadBot) / 2],
            [cx + cx / 2 - 4,  (quadMidY + quadBot) / 2]
        ];
        _quadHalfW = cx / 2;
        _quadHalfH = (quadMidY - quadTop) / 2;

        var slots = pageSlots[currentPage];
        for (var q = 0; q < 4; q++) {
            var dfType = slots[q];
            if (dfType == DF_NONE) { continue; }
            var qc = _quadCenters[q];

            if (dfType == DF_GPS_QNH_ALT) {
                // Combined dual-altitude display
                var fd = DataProvider.getFieldData(dfType, posInfo, hasGps, qnhHpa);
                drawDualQuadrant(dc, qc[0], qc[1], fd);
            } else {
                var fd = DataProvider.getFieldData(dfType, posInfo, hasGps, qnhHpa);
                drawQuadrant(dc, qc[0], qc[1], fd[0], fd[1], fd[2]);
            }
        }

        // --- Bottom persistent field ---
        if (botSlot != DF_NONE) {
            var bd = DataProvider.getFieldData(botSlot, posInfo, hasGps, qnhHpa);
            var botStr = bd[0] + " " + bd[1];
            if (bd.size() == 3 && !bd[2].equals("")) {
                botStr = botStr + bd[2];
            }
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, botBarY - 8, Gfx.FONT_XTINY, botStr, Gfx.TEXT_JUSTIFY_CENTER);
        }

        // --- Page dots ---
        if (totalPages > 1) {
            drawPageDots(dc, cx, botBarY - 24, totalPages, currentPage);
        }
    }

    function drawQuadrant(dc, cx, cy, label, value, unit) {
        var isNoGps = value.equals("NoGPS");

        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 28, Gfx.FONT_XTINY, label, Gfx.TEXT_JUSTIFY_CENTER);

        if (isNoGps) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 14, Gfx.FONT_SMALL, "NoGPS", Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 14, Gfx.FONT_MEDIUM, value, Gfx.TEXT_JUSTIFY_CENTER);
        }

        if (!unit.equals("") && !isNoGps) {
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 12, Gfx.FONT_XTINY, unit, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }

    // Draw combined GPS + QNH altitude in one cell
    // fd = ["GPS", gpsVal, "QNH", qnhVal, "ft"]
    function drawDualQuadrant(dc, cx, cy, fd) {
        var gpsVal = fd[1];
        var qnhVal = fd[3];
        var unit = fd[4];
        var gpsNoGps = gpsVal.equals("NoGPS");
        var qnhNoGps = qnhVal.equals("NoGPS");

        // Top line: GPS altitude
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 36, Gfx.FONT_XTINY, "GPS", Gfx.TEXT_JUSTIFY_CENTER);
        if (gpsNoGps) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 24, Gfx.FONT_SMALL, "NoGPS", Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 24, Gfx.FONT_SMALL, gpsVal + unit, Gfx.TEXT_JUSTIFY_CENTER);
        }

        // Bottom line: QNH altitude
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 2, Gfx.FONT_XTINY, "QNH", Gfx.TEXT_JUSTIFY_CENTER);
        if (qnhNoGps) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 12, Gfx.FONT_SMALL, "NoGPS", Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 12, Gfx.FONT_SMALL, qnhVal + unit, Gfx.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawTrackIndicator(dc, cx, cy, posInfo, hasGps) {
        var r = 14;
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);

        if (!hasGps || posInfo == null || posInfo.heading == null) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 7, Gfx.FONT_XTINY, "---", Gfx.TEXT_JUSTIFY_CENTER);
            return;
        }

        var headRad = posInfo.heading.toFloat();
        var deg = Math.toDegrees(headRad).toNumber();
        if (deg < 0) { deg += 360; }

        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - r - 11, Gfx.FONT_XTINY, "N", Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        var tipX = cx + (r - 2) * Math.sin(headRad);
        var tipY = cy - (r - 2) * Math.cos(headRad);
        dc.drawLine(cx, cy, tipX.toNumber(), tipY.toNumber());

        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx + r + 6, cy - 8, Gfx.FONT_XTINY, deg.format("%03d") + "\u00B0", Gfx.TEXT_JUSTIFY_LEFT);
    }

    function drawPageDots(dc, cx, y, total, current) {
        var dotR = 3;
        var spacing = 10;
        var startX = cx - ((total - 1) * spacing) / 2;
        for (var i = 0; i < total; i++) {
            var x = startX + i * spacing;
            if (i == current) {
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, dotR);
            } else {
                dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, dotR - 1);
            }
        }
    }

    function readPropNum(key, dflt) {
        try {
            var val = Properties.getValue(key);
            if (val != null) { return val.toNumber(); }
        } catch (e) {}
        return dflt;
    }

    function readPropBool(key, dflt) {
        try {
            var val = Properties.getValue(key);
            if (val != null) { return val; }
        } catch (e) {}
        return dflt;
    }
}
