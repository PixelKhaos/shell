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
    required property var modelData

    readonly property bool isActive: session.activeCategory === modelData.id
    readonly property bool collapsed: session.sidebarCollapsed

    width: parent ? parent.width : 0
    height: collapsed ? 64 : 40

    Behavior on height {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    StyledRect {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal

        radius: root.collapsed ? Appearance.rounding.normal : Appearance.rounding.full
        color: root.isActive ? Qt.alpha(Colours.palette.m3secondaryContainer, 1) : "transparent"

        Behavior on radius {
            NumberAnimation {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
        Behavior on color {
            CAnim {}
        }

        StateLayer {
            function onClicked() {
                root.session.setCategory(root.modelData.id);
            }
            color: root.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        }

        MaterialIcon {
            id: btmIcon

            x: root.collapsed ? (parent.width - width) / 2 : Appearance.padding.large
            y: root.collapsed ? (parent.height - height) / 2 - 8 : (parent.height - height) / 2

            text: root.modelData.icon
            color: root.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            font.pointSize: root.collapsed ? Appearance.font.size.large : Appearance.font.size.larger
            fill: root.isActive ? 1 : 0

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
            Behavior on font.pointSize {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
            Behavior on fill {
                Anim {}
            }
        }

        StyledText {
            x: root.collapsed ? (parent.width - width) / 2 : btmIcon.x + btmIcon.width + Appearance.spacing.normal
            y: root.collapsed ? parent.height - height - 6 : (parent.height - height) / 2

            text: root.modelData.label
            color: root.isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            font.pointSize: root.collapsed ? Appearance.font.size.small - 1 : Appearance.font.size.normal
            font.capitalization: Font.Capitalize

            opacity: root.collapsed ? 0.8 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
            Behavior on font.pointSize {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }
}
