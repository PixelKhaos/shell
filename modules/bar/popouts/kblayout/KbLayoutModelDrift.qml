pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import Caelestia

Item {
    id: model

    property alias visibleModel: _visibleModel
    property string activeLabel: Drift.kbLayout + " - " + Drift.kbLayoutFull
    property int activeIndex: -1

    function start() {
        _updateFromService();
    }

    function refresh() {
    }

    function switchTo(idx) {

    }

    function _updateFromService() {
        const currentCode = Drift.kbLayout;
        const layouts = Drift._layoutCodes.map(c => c.toUpperCase());
        
        let idx = -1;
        for (let i = 0; i < layouts.length; i++) {
            if (layouts[i] === currentCode) {
                idx = i;
                break;
            }
        }
        
        model.activeIndex = idx;
        _rebuildVisible(layouts);
    }

    function _rebuildVisible(layouts) {
        _visibleModel.clear();
        
        for (let i = 0; i < layouts.length; i++) {
            if (i === model.activeIndex) continue;
            
            const code = layouts[i];
            _visibleModel.append({
                layoutIndex: i,
                token: code,
                label: code
            });
        }
    }

    visible: false

    Connections {
        target: Drift
        function onKbLayoutFullChanged() {
            model._updateFromService();
        }
    }

    ListModel {
        id: _visibleModel
    }
}
