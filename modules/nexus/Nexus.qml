pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services
import qs.modules.nexus

Item {
    id: root

    required property ShellScreen screen

    readonly property int rounding: floating ? 0 : Appearance.rounding.normal

    property bool floating: false
    property alias active: session.activeCategory
    property alias sidebarCollapsed: session.sidebarCollapsed

    readonly property NexusSession session: NexusSession {
        id: session
        nexusRoot: root
    }

    signal close

    implicitWidth: implicitHeight * 1.67
    implicitHeight: screen.height * 0.85

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        StyledRect {
            id: sidebarContainer

            Layout.fillHeight: true
            Layout.preferredWidth: session.sidebarCollapsed ? 100 : 250
            clip: false

            topLeftRadius: root.rounding
            bottomLeftRadius: root.rounding
            color: Colours.tPalette.m3surfaceContainer

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Sidebar {
                id: sidebar
                anchors.fill: parent
                session: root.session
            }
        }

        StyledRect {
            id: contentOuter

            Layout.fillWidth: true
            Layout.fillHeight: true

            topRightRadius: root.rounding
            bottomRightRadius: root.rounding
            color: Colours.tPalette.m3surfaceContainer

            // Inner content
            Item {
                anchors.fill: parent
                anchors.margins: 10

                StyledRect {
                    id: contentInner
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: Colours.tPalette.m3surface
                    clip: true

                    ContentArea {
                        anchors.fill: parent
                        session: root.session
                    }
                }
            }

            Rectangle {
                id: closeBtn

                anchors.top: parent.top
                anchors.right: parent.right
                width: 40
                height: 40
                color: Colours.tPalette.m3surfaceContainer

                topRightRadius: root.rounding
                bottomLeftRadius: Appearance.rounding.small

                StateLayer {
                    function onClicked() {
                        root.close();
                    }
                    radius: closeBtn.bottomLeftRadius
                    color: Colours.palette.m3onSurface
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurface
                }

                // Fillets will be added via SDF shader module
            }
        }
    }

    SidebarFlyout {
        id: flyout

        session: root.session
        flyoutCategory: sidebar.flyoutCategory
        open: session.sidebarCollapsed && sidebar.flyoutCategory !== ""

        x: sidebarContainer.width + 8
        y: sidebar.flyoutTop

        Behavior on y {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }

        onHoverEntered: sidebar.cancelFlyoutClose()
        onHoverExited: sidebar.scheduleFlyoutClose()
        onChildClicked: function (id) {
            session.setCategory(id);
        }
    }
}
