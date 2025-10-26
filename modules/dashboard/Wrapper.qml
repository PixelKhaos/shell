pragma ComponentBehavior: Bound

import qs.components
import qs.components.filedialog
import qs.config
import qs.utils
import Caelestia
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities
    readonly property PersistentProperties dashState: PersistentProperties {
        property int currentTab
        property date currentDate: new Date()
        property date calendarSelectedDate: new Date()
        property bool calendarShowDayView: false
        property bool calendarEventModalOpen: false
        property string calendarEventModalEventId: ""
        property date calendarEventModalDate: new Date()
        property string calendarDeleteEventId: ""
        property string calendarDeleteEventTitle: ""
        property bool calendarDeleteAllRecurring: false

        reloadableId: "dashboardState"
    }

    Binding {
        target: root.visibilities
        property: "calendarEventModalOpen"
        value: root.dashState.calendarEventModalOpen
    }

    // Close modal when dashboard closes
    Connections {
        target: root.visibilities

        function onDashboardChanged(): void {
            if (!root.visibilities.dashboard) {
                root.dashState.calendarEventModalOpen = false;
                root.dashState.calendarDeleteEventId = "";
                root.dashState.calendarDeleteEventTitle = "";
                root.dashState.calendarDeleteAllRecurring = false;
            }
        }
    }
    
    // Prevent dashboard from closing when modal is open
    Binding {
        target: root.visibilities
        property: "dashboard"
        value: true
        when: root.dashState.calendarEventModalOpen || root.dashState.calendarDeleteEventId !== ""
        restoreMode: Binding.RestoreNone
    }
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property real nonAnimHeight: state === "visible" ? (content.item?.nonAnimHeight ?? 0) : 0

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    onStateChanged: {
        if (state === "visible" && timer.running) {
            timer.triggered();
            timer.stop();
        }
    }

    states: State {
        name: "visible"
        when: root.visibilities.dashboard && Config.dashboard.enabled

        PropertyChanges {
            root.implicitHeight: content.implicitHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Timer {
        id: timer

        running: true
        interval: Appearance.anim.durations.extraLarge
        onTriggered: {
            content.active = Qt.binding(() => (root.visibilities.dashboard && Config.dashboard.enabled) || root.visible);
            content.visible = true;
        }
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        visible: false
        active: true

        sourceComponent: Content {
            visibilities: root.visibilities
            state: root.dashState
            facePicker: root.facePicker
        }
    }
}
