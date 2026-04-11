pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import ".."

ColumnLayout {
    id: root

    required property NexusSession session

    readonly property bool collapsed: session.sidebarCollapsed

    spacing: 0

    // Search bar
    Item {
        id: searchItem

        Layout.fillWidth: true
        Layout.preferredHeight: root.collapsed ? 64 : 44

        Behavior on Layout.preferredHeight {
            NumberAnimation {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        StyledRect {
            id: searchBtn
            anchors.fill: parent

            radius: root.collapsed ? Appearance.rounding.normal : Appearance.rounding.full
            color: {
                if (root.session.searchPopoutOpen && root.collapsed)
                    return Qt.alpha(Colours.palette.m3secondaryContainer, 0.16);
                if (!root.collapsed)
                    return Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.6);
                return "transparent";
            }

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
                    root.session.searchPopoutOpen = !root.session.searchPopoutOpen;
                    root.session.configPopoutOpen = false;
                }
                radius: parent.radius
                color: Colours.palette.m3onSurface
            }

            MaterialIcon {
                id: searchIcon

                x: root.collapsed ? (parent.width - width) / 2 : Appearance.padding.large
                y: root.collapsed ? (parent.height - height) / 2 - 8 : (parent.height - height) / 2

                text: "search"
                font.pointSize: root.collapsed ? Appearance.font.size.large : Appearance.font.size.larger
                color: {
                    if (root.session.searchPopoutOpen && root.collapsed)
                        return Colours.palette.m3primary;
                    return Qt.alpha(Colours.palette.m3onSurface, root.collapsed ? 0.5 : 0.4);
                }

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
                Behavior on color {
                    CAnim {}
                }
            }

            StyledText {
                id: searchLabel

                x: root.collapsed ? (parent.width - width) / 2 : searchIcon.x + searchIcon.width + Appearance.spacing.normal
                y: root.collapsed ? parent.height - height - 6 : (parent.height - height) / 2

                text: root.collapsed ? "Search" : "Search settings..."
                font.pointSize: root.collapsed ? Appearance.font.size.small - 1 : Appearance.font.size.normal
                color: {
                    if (root.session.searchPopoutOpen && root.collapsed)
                        return Colours.palette.m3primary;
                    return Qt.alpha(Colours.palette.m3onSurface, root.collapsed ? 0.7 : 0.3);
                }

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
                Behavior on color {
                    CAnim {}
                }
            }
        }
    }

    Item {
        id: configItem

        Layout.fillWidth: true
        Layout.preferredHeight: root.collapsed ? 64 : 40
        Layout.topMargin: root.collapsed ? 4 : 8

        Behavior on Layout.preferredHeight {
            NumberAnimation {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        StyledRect {
            id: configBtn
            anchors.fill: parent

            radius: root.collapsed ? Appearance.rounding.normal : Appearance.rounding.full
            color: {
                if (root.session.configPopoutOpen)
                    return Qt.alpha(Colours.palette.m3secondaryContainer, root.collapsed ? 0.16 : 0.12);
                if (!root.collapsed)
                    return Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.6);
                return "transparent";
            }

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
                    root.session.configPopoutOpen = !root.session.configPopoutOpen;
                    root.session.searchPopoutOpen = false;
                }
                radius: parent.radius
                color: Colours.palette.m3onSurface
            }

            MaterialIcon {
                id: configIcon

                x: root.collapsed ? (parent.width - width) / 2 : Appearance.padding.large
                y: root.collapsed ? (parent.height - height) / 2 - 8 : (parent.height - height) / 2

                text: root.session.activeConfig === "global" ? "language" : "monitor"
                font.pointSize: root.collapsed ? Appearance.font.size.large : Appearance.font.size.larger
                color: {
                    if (root.session.configPopoutOpen)
                        return Colours.palette.m3primary;
                    return Qt.alpha(Colours.palette.m3onSurface, 0.5);
                }

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
                Behavior on color {
                    CAnim {}
                }
            }

            StyledText {
                id: configLabel

                x: root.collapsed ? (parent.width - width) / 2 : configIcon.x + configIcon.width + Appearance.spacing.normal
                y: root.collapsed ? parent.height - height - 6 : (parent.height - height) / 2

                text: root.session.activeConfig === "global" ? "Global" : root.session.activeConfig
                font.pointSize: root.collapsed ? Appearance.font.size.small - 1 : Appearance.font.size.normal
                font.weight: Font.Medium
                color: {
                    if (root.session.configPopoutOpen)
                        return Colours.palette.m3primary;
                    return Qt.alpha(Colours.palette.m3onSurface, root.collapsed ? 0.7 : 0.6);
                }

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
                Behavior on color {
                    CAnim {}
                }
            }

            MaterialIcon {
                id: configChevron

                anchors.right: parent.right
                anchors.rightMargin: Appearance.padding.large
                anchors.verticalCenter: parent.verticalCenter

                text: "expand_more"
                font.pointSize: Appearance.font.size.normal
                color: Qt.alpha(Colours.palette.m3onSurface, 0.4)
                rotation: root.session.configPopoutOpen ? 180 : 0
                opacity: root.collapsed ? 0 : 1

                Behavior on rotation {
                    NumberAnimation {
                        duration: Appearance.anim.durations.small
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                    }
                }
                Behavior on opacity {
                    Anim {}
                }
            }
        }
    }

    // Separator
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.leftMargin: Appearance.padding.normal
        Layout.rightMargin: Appearance.padding.normal
        Layout.topMargin: root.collapsed ? 8 : Appearance.spacing.normal
        color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
    }
}
