pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Blobs
import qs.components
import qs.services
import qs.config
import qs.modules.nexus
import "./components"

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

    readonly property bool flyoutOverlapsSearch: flyout.open && searchPopoutContent.open && flyout.y < searchPopoutContent.y + searchPopoutContent.drawerHeight && flyout.y + flyout.drawerHeight > searchPopoutContent.y
    readonly property bool flyoutOverlapsConfig: flyout.open && configPopoutContent.open && flyout.y < configPopoutContent.y + configPopoutContent.drawerHeight && flyout.y + flyout.drawerHeight > configPopoutContent.y

    signal close

    implicitWidth: implicitHeight * 1.67
    implicitHeight: screen.height * 0.85

    Item {
        id: blobLayer

        anchors.fill: parent

        BlobGroup {
            id: blobGroup

            color: Colours.tPalette.m3surfaceContainer
            smoothing: 16

            Behavior on color {
                CAnim {}
            }
        }

        // Border frame
        BlobInvertedRect {
            property real pad: 50

            anchors.fill: parent
            anchors.margins: -pad
            group: blobGroup
            radius: Appearance.rounding.small
            borderLeft: sidebarContainer.width + 10 + pad
            borderTop: 10 + pad
            borderRight: 10 + pad
            borderBottom: 10 + pad
        }

        BlobRect {
            id: notchBlob

            group: blobGroup
            x: root.width - (closeBtn.width + maximizeBtn.width)
            y: 0
            implicitWidth: closeBtn.width + maximizeBtn.width
            implicitHeight: closeBtn.height
            radius: 0
            bottomLeftRadius: Appearance.rounding.small
            deformScale: 0
        }
    }

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
            color: "transparent"

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                }
            }

            Sidebar {
                id: sidebar

                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                session: root.session
            }
        }

        StyledRect {
            id: contentOuter

            Layout.fillWidth: true
            Layout.fillHeight: true

            topRightRadius: root.rounding
            bottomRightRadius: root.rounding
            color: "transparent"

            Item {
                anchors.fill: parent
                anchors.margins: 10

                StyledRect {
                    id: contentInner

                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: "transparent"
                    clip: true

                    ContentArea {
                        anchors.fill: parent
                        session: root.session
                    }
                }
            }
        }
    }

    // Overlay blobs
    Item {
        x: sidebarContainer.width
        y: 0
        width: root.width - sidebarContainer.width
        height: root.height
        clip: true

        BlobRect {
            id: flyoutBlob

            group: blobGroup
            x: flyout.x - sidebarContainer.width
            y: flyout.y
            implicitWidth: flyout.drawerWidth
            implicitHeight: flyout.drawerHeight
            radius: Appearance.rounding.small
            topLeftRadius: 0
            bottomLeftRadius: 0
            topRightRadius: flyout.y <= 0 ? 0 : Appearance.rounding.small
            deformScale: 0.00001
            stiffness: 200
            damping: 16
        }

        BlobRect {
            id: searchPopoutBlob

            group: blobGroup
            x: searchPopoutContent.x - sidebarContainer.width
            y: searchPopoutContent.y
            implicitWidth: searchPopoutContent.drawerWidth
            implicitHeight: searchPopoutContent.drawerHeight
            visible: session.sidebarCollapsed
            radius: Appearance.rounding.normal
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 0
            deformScale: 0.00001
            stiffness: 200
            damping: 16
        }

        BlobRect {
            id: configPopoutBlob

            group: blobGroup
            x: configPopoutContent.x - sidebarContainer.width
            y: 0
            implicitWidth: configPopoutContent.drawerWidth
            implicitHeight: configPopoutContent.drawerHeight
            visible: session.sidebarCollapsed
            radius: Appearance.rounding.normal
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 0
            deformScale: 0.00001
            stiffness: 200
            damping: 16
        }
    }

    Rectangle {
        id: closeBtn

        property bool hovered: closeMA.containsMouse

        x: root.width - width
        y: 0
        width: 40
        height: 40

        color: "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            text: "close"
            font.pointSize: Appearance.font.size.larger
            color: closeBtn.hovered ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
        }

        MouseArea {
            id: closeMA

            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.close()
        }
    }

    Rectangle {
        id: maximizeBtn

        property bool hovered: maxMA.containsMouse

        x: root.width - closeBtn.width - width
        y: 0
        width: 44
        height: 40
        color: "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            text: root.floating ? "fullscreen" : "fullscreen_exit"
            font.pointSize: Appearance.font.size.normal
            color: maximizeBtn.hovered ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        MouseArea {
            id: maxMA

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                Hyprland.dispatch("togglefloating");
                root.floating = !root.floating;
            }
        }
    }

    SidebarFlyout {
        id: flyout

        session: root.session
        flyoutCategory: sidebar.flyoutCategory
        open: session.sidebarCollapsed && sidebar.flyoutCategory !== ""

        x: sidebarContainer.width
        y: sidebar.flyoutTop

        onHoverEntered: sidebar.cancelFlyoutClose()
        onHoverExited: sidebar.scheduleFlyoutClose()
        onChildClicked: function (id) {
            session.setCategory(id);
        }

        Behavior on y {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }
    }

    SidebarPopout {
        id: searchPopoutContent

        x: sidebarContainer.width
        y: 0
        visible: session.sidebarCollapsed
        touchingTop: true
        extraLeftMargin: root.flyoutOverlapsSearch ? flyout.drawerWidth : 0
        flyoutDrawerWidth: flyout.drawerWidth
        flyoutOpen: flyout.open

        open: session.searchPopoutOpen
        popoutWidth: 280

        SearchEngine {
            session: root.session // qmllint disable incompatible-type
        }
    }

    SidebarPopout {
        id: configPopoutContent

        x: sidebarContainer.width
        y: 0
        visible: session.sidebarCollapsed
        touchingTop: true
        extraLeftMargin: root.flyoutOverlapsConfig ? flyout.drawerWidth : 0
        flyoutDrawerWidth: flyout.drawerWidth
        flyoutOpen: flyout.open

        open: session.configPopoutOpen
        popoutWidth: 275

        ConfigSwitcher {
            session: root.session // qmllint disable incompatible-type
        }
    }

    MouseArea {
        x: sidebarContainer.width
        y: 0
        width: parent.width - sidebarContainer.width
        height: parent.height
        z: -1
        visible: session.sidebarCollapsed && (session.searchPopoutOpen || session.configPopoutOpen)

        onClicked: {
            session.searchPopoutOpen = false;
            session.configPopoutOpen = false;
        }
    }
}
