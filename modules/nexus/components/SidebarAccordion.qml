pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config
import ".."

Item {
    id: root

    required property NexusSession session
    required property var childItems
    required property bool open

    width: parent ? parent.width + 2 : 0
    height: open ? col.implicitHeight : 0
    clip: true

    Behavior on height {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    // Vertical line indicator
    Rectangle {
        x: Appearance.padding.large + 16
        y: 0
        width: 1
        height: root.open ? col.height : 0
        color: Qt.alpha(Colours.palette.m3onSurface, 0.12)

        Behavior on height {
            NumberAnimation {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

    Column {
        id: col

        width: parent.width - (Appearance.padding.large / 2)
        topPadding: Appearance.spacing.small
        leftPadding: Appearance.padding.large
        spacing: Appearance.spacing.small

        Repeater {
            model: root.childItems

            delegate: Item {
                id: childDelegate

                required property var modelData

                readonly property bool isActive: root.session.activeCategory === childDelegate.modelData.id

                width: col.width
                height: 36

                StyledRect {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.larger * 2
                    anchors.rightMargin: Appearance.padding.normal

                    radius: Appearance.rounding.full
                    color: childDelegate.isActive ? Qt.alpha(Colours.palette.m3primary, 0.16) : "transparent"

                    Behavior on color {
                        CAnim {}
                    }

                    StateLayer {
                        function onClicked() {
                            root.session.setCategory(childDelegate.modelData.id);
                        }

                        color: childDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.padding.large
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: childDelegate.modelData.icon
                            color: childDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.normal
                            fill: childDelegate.isActive ? 1 : 0
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: childDelegate.modelData.label
                            color: childDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.smaller
                            font.capitalization: Font.Capitalize
                        }
                    }
                }
            }
        }
    }
}
