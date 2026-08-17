using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Graphics as Gfx;

class PageDelegate extends Ui.BehaviorDelegate {
    var _view;
    var _lastTapTime = 0;
    var _lastTapField = 0;
    const DOUBLE_TAP_MS = 500;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSwipe(swipeEvent) {
        var dir = swipeEvent.getDirection();
        if (dir == Ui.SWIPE_LEFT) { _view.nextPage(); }
        else if (dir == Ui.SWIPE_RIGHT) { _view.prevPage(); }
        return true;
    }

    function onTap(clickEvent) {
        var coords = clickEvent.getCoordinates();
        var field = _view.getFieldAtPosition(coords[0], coords[1]);
        var now = System.getTimer();
        if (field == _lastTapField && field != DF_NONE && (now - _lastTapTime) < DOUBLE_TAP_MS) {
            _lastTapTime = 0;
            _lastTapField = DF_NONE;
            return handleDoubleTap(field);
        }
        _lastTapTime = now;
        _lastTapField = field;
        return false;
    }

    function handleDoubleTap(field) {
        if (field == DF_QNH_ALT || field == DF_GPS_QNH_ALT) {
            var qnhView = new QnhInputView(_view);
            Ui.pushView(qnhView, new QnhInputDelegate(qnhView, _view), Ui.SLIDE_UP);
            return true;
        }
        return false;
    }

    // Long press on screen -> exit confirmation
    function onHold(clickEvent) {
        Ui.pushView(new ExitConfirmView(), new ExitConfirmDelegate(), Ui.SLIDE_UP);
        return true;
    }

    function onBack() {
        _view.prevPage();
        return true;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_DOWN || key == Ui.KEY_ENTER) { _view.nextPage(); return true; }
        else if (key == Ui.KEY_UP) { _view.prevPage(); return true; }
        return false;
    }
}

// ===== Exit confirmation view =====
class ExitConfirmView extends Ui.View {
    function initialize() { View.initialize(); }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 50, Gfx.FONT_MEDIUM, "Quitter", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy - 20, Gfx.FONT_MEDIUM, "AviData ?", Gfx.TEXT_JUSTIFY_CENTER);

        // Oui (right side)
        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx + 60, cy + 40, Gfx.FONT_MEDIUM, "Oui", Gfx.TEXT_JUSTIFY_CENTER);

        // Non (left side)
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx - 60, cy + 40, Gfx.FONT_MEDIUM, "Non", Gfx.TEXT_JUSTIFY_CENTER);
    }
}

class ExitConfirmDelegate extends Ui.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }

    function onTap(clickEvent) {
        var coords = clickEvent.getCoordinates();
        var cx = System.getDeviceSettings().screenWidth / 2;
        if (coords[0] > cx) {
            // Oui -> exit
            System.exit();
        } else {
            // Non -> cancel
            Ui.popView(Ui.SLIDE_DOWN);
        }
        return true;
    }

    function onBack() {
        Ui.popView(Ui.SLIDE_DOWN);
        return true;
    }
}
