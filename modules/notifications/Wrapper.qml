import qs.components
import qs.config
import QtQuick

Item {
    id: root

    property bool fullscreenOnly
    property bool hasFullscreen
    required property var visibilities
    required property var panels
    readonly property QtObject fallbackVisibilities: QtObject {
        property bool sidebar: false
        property bool osd: false
        property bool session: false
    }

    visible: height > 0
    implicitWidth: Math.max(panels?.sidebar?.width ?? 0, content.implicitWidth)
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

        visible: !!root.visibilities
        visibilities: root.visibilities ?? root.fallbackVisibilities
        panels: root.panels
    }
}
