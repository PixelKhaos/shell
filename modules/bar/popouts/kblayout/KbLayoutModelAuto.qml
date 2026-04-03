pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Item {
    id: root

    property var visibleModel: _loader.item ? _loader.item.visibleModel : null
    property string activeLabel: _loader.item ? _loader.item.activeLabel : ""
    property int activeIndex: _loader.item ? _loader.item.activeIndex : -1

    function start() {
        if (_loader.item) {
            _loader.item.start();
        }
    }

    function refresh() {
        if (_loader.item) {
            _loader.item.refresh();
        }
    }

    function switchTo(idx) {
        if (_loader.item) {
            _loader.item.switchTo(idx);
        }
    }

    Loader {
        id: _loader
        
        onLoaded: {
            if (item) {
                item.start();
            }
        }
        
        Component.onCompleted: {
            // Check for Hyprland
            if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) {
                source = "KbLayoutModel.qml";
            } else {
                // Assume Driftwm
                source = "KbLayoutModelDrift.qml";
            }
        }
    }
}
