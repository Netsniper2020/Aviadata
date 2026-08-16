using Toybox.WatchUi as Ui;
using Toybox.System;

class PageDelegate extends Ui.BehaviorDelegate {
    var _view;

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

    function onBack() {
        // Exit the app
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
