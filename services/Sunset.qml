pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias enabled: props.manualEnabled
    property alias temperature: props.temperature
    property alias autoMode: props.autoMode

    // 9 PM (21) to 6 AM (6)
    readonly property bool isNight: {
        const now = new Date();
        const hour = now.getHours();
        return hour >= 21 || hour < 6;
    }


    readonly property bool active: autoMode ? isNight : enabled


    onActiveChanged: updateProcess()
    onTemperatureChanged: if (active) updateTimer.restart()

    PersistentProperties {
        id: props
        property bool manualEnabled: false
        property bool autoMode: true
        property int temperature: 4800
        reloadableId: "sunsetService"
    }

    Process {
        id: sunsetProcess
        command: ["hyprsunset", "-t", props.temperature.toString()]
    }

    function updateProcess() {
        sunsetProcess.running = false;

        if (active) {
            console.log("Starting hyprsunset at " + props.temperature + "K");
            sunsetProcess.running = true;
        } else {
            console.log("Stopping hyprsunset");
            killProcess.running = true;
        }
    }

    // Backup pkill since sometimes Wayland binaries hang
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

    // routine check for automation
    Timer {
        interval: 60000
        running: props.autoMode
        repeat: true
        onTriggered: {
            let nightCheck = isNight;
            if (active != nightCheck) updateProcess();
        }
    }
}
