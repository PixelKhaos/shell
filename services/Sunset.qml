pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Public API - Simplified to only manual control
    property alias enabled: props.manualEnabled
    property alias temperature: props.temperature

    // active is now just a direct alias of enabled
    readonly property bool active: enabled

    onActiveChanged: updateProcess()
    onTemperatureChanged: if (active) updateTimer.restart()

    PersistentProperties {
        id: props
        property bool manualEnabled: false
        property int temperature: 3000
        reloadableId: "sunsetService"
    }

    Process {
        id: sunsetProcess
        command: ["hyprsunset", "-t", props.temperature.toString()]
    }

    function updateProcess() {
        sunsetProcess.running = false;
        if (active) {
            sunsetProcess.running = true;
        } else {
            // Clean up the binary when disabled
            killProcess.running = true;
        }
    }

    Process {
        id: killProcess
        command: ["pkill", "hyprsunset"]
        onExited: running = false
    }

    Timer {
        id: updateTimer
        interval: 300
        onTriggered: updateProcess()
    }
}
