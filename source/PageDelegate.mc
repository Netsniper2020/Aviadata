using Toybox.WatchUi as Ui;
using Toybox.System;

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
        if (dir == Ui.SWIPE_LEFT) {
            _view.nextPage();
            return true;
        } else if (dir == Ui.SWIPE_RIGHT) {
            _view.prevPage();
            return true;
        }
        return false;
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

    function onBack() {
        System.exit();
        return true;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_DOWN || key == Ui.KEY_ENTER) {
            _view.nextPage();
            return true;
        } else if (key == Ui.KEY_UP) {
            _view.prevPage();
            return true;
        }
        return false;
    }
}
