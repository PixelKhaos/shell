pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import ".."

Item {
    id: root

    required property NexusSession session
    required property var childItems
    required property bool open

    width: parent ? parent.width : 0
    height: open ? col.implicitHeight : 0
    clip: true

    Behavior on height {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Column {
        id: col
        width: parent.width
        topPadding: Appearance.spacing.small
        spacing: Appearance.spacing.small

        Repeater {
            model: root.childItems

            delegate: Item {
                id: childDelegate
                required property var modelData

                width: col.width
                height: 36

                readonly property bool isActive: root.session.activeCategory === childDelegate.modelData.id

                StyledRect {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.padding.larger * 2
                    anchors.rightMargin: Appearance.padding.normal

                    radius: Appearance.rounding.full
                    color: childDelegate.isActive ? Qt.alpha(Colours.palette.m3secondaryContainer, 1) : "transparent"

                    Behavior on color {
                        CAnim {}
                    }

                    StateLayer {
                        function onClicked() {
                            root.session.setCategory(childDelegate.modelData.id);
                        }
                        color: childDelegate.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.padding.large
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: childDelegate.modelData.icon
                            color: childDelegate.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.normal
                            fill: childDelegate.isActive ? 1 : 0
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: childDelegate.modelData.label
                            color: childDelegate.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.smaller
                            font.capitalization: Font.Capitalize
                        }
                    }
                }
            }
        }
    }
}
