pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

Item {
    id: root

    required property bool open
    property int popoutWidth: 320
    property int popoutPadding: 16
    property bool touchingTop: false

    default property alias content: contentLayout.children

    implicitWidth: root.open ? popoutWidth + 20 : 0
    implicitHeight: drawer.height + 20

    Rectangle {
        id: drawer

        x: 10
        y: 10
        clip: true
        width: root.open ? root.popoutWidth : 0
        height: contentLayout.implicitHeight + root.popoutPadding * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: 0
        topRightRadius: root.touchingTop ? 0 : Appearance.rounding.normal
        bottomRightRadius: Appearance.rounding.normal

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
