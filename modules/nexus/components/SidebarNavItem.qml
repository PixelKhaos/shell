pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config
import ".."

Item {
    id: root

    required property NexusSession session
    required property var modelData

    readonly property string catId: modelData.id
    readonly property bool isDirect: modelData.isDirect
    readonly property bool hasChildren: modelData.children && modelData.children.length > 0
    readonly property bool isActive: session.activeCategory === catId
    readonly property bool isChildActive: NexusRegistry.isChildActive(catId, session.activeCategory) // qmllint disable missing-property
    readonly property bool collapsed: session.sidebarCollapsed

    property bool hovered: false
    property bool flyoutActive: false
    
    signal flyoutRequested(real itemY)
    signal flyoutCloseRequested

    width: parent ? parent.width : 0
    height: collapsed ? 68 : 40

    Behavior on height {
        NumberAnimation {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    StyledRect {
        id: navBtn

        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal

        radius: root.collapsed ? Appearance.rounding.normal : Appearance.rounding.full
        color: {
            if (root.isActive || root.isChildActive)
                return Qt.alpha(Colours.palette.m3primary, 0.16);
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
                if (root.isDirect) {
                    root.session.setCategory(root.catId);
                } else if (root.collapsed) {
                    if (root.hasChildren)
                        root.session.setCategory(root.modelData.children[0].id);
                } else {
                    root.session.expandedCategory = root.session.expandedCategory === root.catId ? "" : root.catId;
                }
            }

            color: root.isActive || root.isChildActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
        }

        MaterialIcon {
            id: navIcon

            x: {
                if (!root.collapsed)
                    return Appearance.padding.large;
                const baseX = (parent.width - width) / 2;
                return root.hasChildren && (root.hovered || root.flyoutActive) ? baseX - 6 : baseX;
            }
            y: root.collapsed ? (parent.height - height) / 2 - 10 : (parent.height - height) / 2

            text: root.modelData.icon
            color: root.isActive || root.isChildActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
            font.pointSize: root.collapsed ? Appearance.font.size.large + 2 : Appearance.font.size.larger
            fill: root.isActive || root.isChildActive ? 1 : 0
            scale: root.collapsed && root.hasChildren && (root.hovered || root.flyoutActive) ? 0.8 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
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
            Behavior on fill {
                Anim {}
            }
        }

        StyledText {
            id: navLabel

            x: root.collapsed ? (parent.width - width) / 2 : navIcon.x + navIcon.width + Appearance.spacing.normal
            y: root.collapsed ? parent.height - height - 6 : (parent.height - height) / 2

            text: root.collapsed ? (root.modelData.label.length > 8 ? root.modelData.label.substring(0, 7) + "…" : root.modelData.label) : root.modelData.label
            color: root.isActive || root.isChildActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
            font.pointSize: root.collapsed ? Appearance.font.size.small - 1 : Appearance.font.size.normal
            font.capitalization: Font.Capitalize
            font.weight: Font.Medium

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

        MaterialIcon {
            id: navChevron

            visible: root.hasChildren && !root.collapsed
            anchors.right: parent.right
            anchors.rightMargin: Appearance.padding.large
            anchors.verticalCenter: parent.verticalCenter

            text: "expand_more"
            color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
            font.pointSize: Appearance.font.size.normal
            rotation: root.session.expandedCategory === root.catId ? 180 : 0
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

        MaterialIcon {
            id: doubleChevron

            visible: root.collapsed && root.hasChildren
            x: (parent.width - width) / 2 + 15
            y: (parent.height - height) / 2 - 10

            text: "keyboard_double_arrow_right"
            color: root.isActive || root.isChildActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.large
            opacity: (root.hovered || root.flyoutActive) ? 0.9 : 0.0
            scale: (root.hovered || root.flyoutActive) ? 0.9 : 0.6

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }

        HoverHandler {
            enabled: root.collapsed && root.hasChildren
            onHoveredChanged: {
                root.hovered = hovered;
                if (hovered) {
                    root.flyoutRequested(root.mapToItem(null, 0, 0).y);
                } else {
                    root.flyoutCloseRequested();
                }
            }
        }
    }
}
