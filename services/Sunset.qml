pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias enabled: props.manualEnabled
    property alias temperature: props.temperature
    property alias autoMode: props.autoMode

    // Final state: ON if manually enabled OR (Auto is ON and it's Night)
    readonly property bool active: enabled || (autoMode && isNight)

    // Internal Night State (Updating every minute)
    property bool isNight: false
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const hour = new Date().getHours();
            isNight = (hour >= 21 || hour < 6); // 9PM - 6AM per your latest design
        }
    }

    onActiveChanged: updateProcess()
    onTemperatureChanged: if (active) updateTimer.restart()

    PersistentProperties {
        id: props
        property bool manualEnabled: false
        property bool autoMode: true
        property int temperature: 4200
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
            killProcess.running = true;
        }
    }

    Process { id: killProcess; command: ["pkill", "hyprsunset"]; onExited: running = false }
    Timer { id: updateTimer; interval: 300; onTriggered: updateProcess() }
}
