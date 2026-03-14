pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.modules.notifications as Notifications
import qs.modules.utilities.toasts as Toasts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Variants {
    model: Screens.screens

    StyledWindow {
        id: win

        required property ShellScreen modelData
        readonly property var monitor: Hypr.monitorFor(modelData)
        readonly property bool hasFullscreen: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen === 2) ?? false
        readonly property var visibilities: Visibilities.screens.get(monitor)
        readonly property var panels: Visibilities.panels.get(monitor)
        readonly property QtObject fallbackVisibilities: QtObject {
            property bool sidebar: false
            property bool osd: false
            property bool session: false
            property bool launcher: false
            property bool dashboard: false
            property bool utilities: false
            property bool bar: false
        }
        readonly property QtObject fallbackPanels: QtObject {
            property QtObject sidebar: QtObject {
                property bool visible: false
                property real width: 0
                property real left: 0
            }
            property QtObject utilities: QtObject {
                property real top: 0
            }
            property QtObject osd: QtObject {
                property real y: 0
            }
            property QtObject session: QtObject {
                property real y: 0
            }
        }

        screen: modelData
        name: "fullscreen-overlay"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        mask: Region {}
        visible: hasFullscreen

        Item {
            anchors.fill: parent
            anchors.margins: Config.border.thickness
            anchors.leftMargin: (Visibilities.bars.get(win.monitor)?.implicitWidth ?? Config.border.thickness)

            Notifications.Wrapper {
                visibilities: win.visibilities ?? win.fallbackVisibilities
                panels: win.panels ?? win.fallbackPanels
                fullscreenOnly: true
                hasFullscreen: win.hasFullscreen

                anchors.top: parent.top
                anchors.right: parent.right
            }

            Toasts.Toasts {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: Appearance.padding.normal

                fullscreenOnly: true
                hasFullscreen: win.hasFullscreen
            }
        }
    }
}
