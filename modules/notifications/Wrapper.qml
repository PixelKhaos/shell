import QtQuick
import qs.components
import qs.config

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property bool fullscreenOnly: false
    property bool hasFullscreen: false

    visible: height > 0
    implicitWidth: Math.max(sidebarPanel?.width ?? 0, content.implicitWidth)
    implicitHeight: content.implicitHeight

    states: State {
        name: "hidden"
        when: ((root.visibilities?.sidebar ?? false) && Config.sidebar.enabled) || (root.fullscreenOnly && (!root.hasFullscreen || Config.notifs.fullscreen === "off"))

        PropertyChanges {
            root.implicitHeight: 0
        }
    }

    transitions: Transition {
        Anim {
            target: root
            property: "implicitHeight"
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Content {
        id: content

        visibilities: root.visibilities
        osdPanel: root.sidebarPanel
        sessionPanel: root.sidebarPanel
    }
}
