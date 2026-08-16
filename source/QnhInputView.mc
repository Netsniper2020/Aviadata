using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application.Properties;

class QnhInputView extends Ui.View {
    var _qnh = 1013;
    var _pageView;

    function initialize(pageView) {
        View.initialize();
        _pageView = pageView;
        _qnh = pageView.qnhHpa;
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        // Title
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 80, Gfx.FONT_SMALL, "QNH (hPa)", Gfx.TEXT_JUSTIFY_CENTER);

        // Value
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 30, Gfx.FONT_NUMBER_MILD, _qnh.toString(), Gfx.TEXT_JUSTIFY_CENTER);

        // + button area
        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx + 70, cy - 30, Gfx.FONT_LARGE, "+", Gfx.TEXT_JUSTIFY_CENTER);

        // - button area
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx - 70, cy - 30, Gfx.FONT_LARGE, "-", Gfx.TEXT_JUSTIFY_CENTER);

        // Standard reference
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 40, Gfx.FONT_XTINY, "STD: 1013", Gfx.TEXT_JUSTIFY_CENTER);

        // Instructions
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 65, Gfx.FONT_XTINY, "Tap +/- | Swipe: \u00B110", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + 85, Gfx.FONT_XTINY, "Back = valider", Gfx.TEXT_JUSTIFY_CENTER);
    }

    function adjustQnh(delta) {
        _qnh += delta;
        if (_qnh < 900) { _qnh = 900; }
        if (_qnh > 1100) { _qnh = 1100; }
        Ui.requestUpdate();
    }

    function saveAndClose() {
        // Save to properties
        Properties.setValue("qnhValue", _qnh);
        // Update page view
        _pageView.qnhHpa = _qnh;
        // Pop this view
        Ui.popView(Ui.SLIDE_DOWN);
    }
}

class QnhInputDelegate extends Ui.BehaviorDelegate {
    var _qnhView;
    var _pageView;

    function initialize(qnhView, pageView) {
        BehaviorDelegate.initialize();
        _qnhView = qnhView;
        _pageView = pageView;
    }

    function onTap(clickEvent) {
        var coords = clickEvent.getCoordinates();
        var tapX = coords[0];
        var cx = System.getDeviceSettings().screenWidth / 2;

        if (tapX > cx + 30) {
            _qnhView.adjustQnh(1);
            return true;
        } else if (tapX < cx - 30) {
            _qnhView.adjustQnh(-1);
            return true;
        }
        return false;
    }

    function onSwipe(swipeEvent) {
        var dir = swipeEvent.getDirection();
        if (dir == Ui.SWIPE_UP) {
            _qnhView.adjustQnh(10);
            return true;
        } else if (dir == Ui.SWIPE_DOWN) {
            _qnhView.adjustQnh(-10);
            return true;
        }
        return false;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP) {
            _qnhView.adjustQnh(1);
            return true;
        } else if (key == Ui.KEY_DOWN) {
            _qnhView.adjustQnh(-1);
            return true;
        }
        return false;
    }

    function onBack() {
        _qnhView.saveAndClose();
        return true;
    }
}
