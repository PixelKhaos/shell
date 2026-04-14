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
    property real extraLeftMargin: 0
    property real flyoutDrawerWidth: 0
    property bool flyoutOpen: false

    readonly property real drawerWidth: drawer.width
    readonly property real drawerHeight: drawer.height

    default property alias content: contentLayout.children

    implicitWidth: drawer.width
    implicitHeight: drawer.height

    Rectangle {
        id: drawer

        clip: true
        width: root.open ? root.popoutWidth + root.extraLeftMargin : 0
        height: contentLayout.implicitHeight + root.popoutPadding * 2

        color: "transparent"
        radius: 0

        Behavior on width {
            enabled: root.flyoutOpen === (root.flyoutDrawerWidth >= 100)
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            anchors.leftMargin: root.open ? root.popoutPadding + root.extraLeftMargin : 0
            anchors.rightMargin: root.open ? root.popoutPadding : 0
            anchors.topMargin: root.open ? root.popoutPadding : 0
            anchors.bottomMargin: root.open ? root.popoutPadding : 0
            spacing: Appearance.spacing.normal

            opacity: root.open ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.open ? 200 : 120
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on anchors.leftMargin {
                enabled: root.flyoutOpen === (root.flyoutDrawerWidth >= 100)
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                }
            }

            Behavior on anchors.rightMargin {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                }
            }

            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                }
            }

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                }
            }
        }
    }
}
