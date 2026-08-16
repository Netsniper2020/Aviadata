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

    var pageSlots = null;
    var topSlot = -1;
    var botSlot = -1;

    var qnhHpa = 1013;
    var showTrackTop = true;

    // 1-second refresh timer
    var _timer = null;

    // Cached quadrant centers for tap detection [page][quad] = [x, y]
    var _quadCenters = null;
    var _quadHalfW = 0;
    var _quadHalfH = 0;

    function initialize() {
        View.initialize();
        pageSlots = new [MAX_PAGES];
        for (var p = 0; p < MAX_PAGES; p++) {
            pageSlots[p] = [-1, -1, -1, -1];
        }
        loadSettings();
    }

    function onShow() {
        // Start 1-second timer for live seconds display
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        _timer.start(method(:onTick), 1000, true);
    }

    function onHide() {
        if (_timer != null) {
            _timer.stop();
        }
    }

    function onTick() as Void {
        Ui.requestUpdate();
    }

    function loadSettings() {
        qnhHpa = readPropNum("qnhValue", 1013);
        showTrackTop = readPropBool("showTrackTop", true);

        for (var p = 0; p < MAX_PAGES; p++) {
            pageSlots[p] = [-1, -1, -1, -1];
        }
        topSlot = -1;
        botSlot = -1;

        for (var df = 0; df < DF_COUNT; df++) {
            var posVal = readPropNum(PROP_KEYS[df], 0);
            if (posVal == POS_NA || posVal < 0 || posVal > 18) {
                continue;
            }
            if (posVal == POS_TOP) {
                topSlot = df;
            } else if (posVal == POS_BOT) {
                botSlot = df;
            } else {
                var page = (posVal - 1) / 4;
                var quad = (posVal - 1) % 4;
                if (page >= 0 && page < MAX_PAGES && quad >= 0 && quad < 4) {
                    pageSlots[page][quad] = df;
                }
            }
        }

        totalPages = 0;
        for (var p = 0; p < MAX_PAGES; p++) {
            for (var q = 0; q < 4; q++) {
                if (pageSlots[p][q] != -1) {
                    if (p + 1 > totalPages) {
                        totalPages = p + 1;
                    }
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

    // Returns dfType at tap coordinates, or -1
    function getFieldAtPosition(tapX, tapY) {
        if (_quadCenters == null) {
            return -1;
        }
        var slots = pageSlots[currentPage];
        for (var q = 0; q < 4; q++) {
            if (slots[q] == -1) { continue; }
            var qc = _quadCenters[q];
            var dx = tapX - qc[0];
            var dy = tapY - qc[1];
            if (dx < 0) { dx = -dx; }
            if (dy < 0) { dy = -dy; }
            if (dx < _quadHalfW && dy < _quadHalfH) {
                return slots[q];
            }
        }
        return -1;
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

        var trackAreaH = 0;
        if (showTrackTop) {
            trackAreaH = 30;
        }

        var quadTop = topBarY + 16 + trackAreaH;
        var quadBot = botBarY - 16;
        var quadMidY = (quadTop + quadBot) / 2;

        // --- Top persistent field ---
        if (topSlot != -1) {
            var td = DataProvider.getFieldData(topSlot, posInfo, hasGps, qnhHpa);
            var topStr = td[0] + " " + td[1];
            if (!td[2].equals("")) {
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
            if (dfType == -1) { continue; }
            var fd = DataProvider.getFieldData(dfType, posInfo, hasGps, qnhHpa);
            var qc = _quadCenters[q];
            drawQuadrant(dc, qc[0], qc[1], fd[0], fd[1], fd[2], hasGps);
        }

        // --- Bottom persistent field ---
        if (botSlot != -1) {
            var bd = DataProvider.getFieldData(botSlot, posInfo, hasGps, qnhHpa);
            var botStr = bd[0] + " " + bd[1];
            if (!bd[2].equals("")) {
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

    function drawQuadrant(dc, cx, cy, label, value, unit, hasGps) {
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
