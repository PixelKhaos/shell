pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: root

    required property bool open
    property int popoutWidth: 320
    property int popoutPadding: 16
    property bool touchingTop: false

    readonly property real drawerWidth: drawer.width
    readonly property real drawerHeight: drawer.height

    default property alias content: contentLayout.children

    implicitWidth: drawer.width
    implicitHeight: drawer.height

    Rectangle {
        id: drawer

        clip: true
        width: root.open ? root.popoutWidth : 0
        height: contentLayout.implicitHeight + root.popoutPadding * 2

        color: "transparent"
        radius: 0

        Behavior on width {
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            anchors.margins: root.open ? root.popoutPadding : 0
            spacing: Appearance.spacing.normal

            opacity: root.open ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.open ? 200 : 120
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on anchors.margins {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                }
            }
        }
    }
}
