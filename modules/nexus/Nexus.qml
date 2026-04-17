pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus
import "./components"

Item {
    id: root

    required property ShellScreen screen

    readonly property int rounding: floating ? 0 : Tokens.rounding.normal
    readonly property int borderPad: 50

    property bool floating: false
    property alias active: session.activeCategory
    property alias sidebarCollapsed: session.sidebarCollapsed

    readonly property NexusSession session: NexusSession {
        id: session

        nexusRoot: root
    }

    readonly property bool flyoutOverlapsPopout: flyout.open && unifiedPopout.open && flyout.y < unifiedPopout.y + unifiedPopout.drawerHeight && flyout.y + flyout.drawerHeight > unifiedPopout.y

    signal close

    implicitWidth: implicitHeight * 1.67
    implicitHeight: screen.height * 0.85

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
                radius: Tokens.rounding.small
                color: "transparent"
                clip: true

                ContentArea {
                    anchors.fill: parent
                    session: root.session
                }
            }
        }
    }

    Item {
        id: blobLayer

        anchors.fill: parent
        opacity: Colours.tPalette.m3surfaceContainer.a
        layer.enabled: true // So children don't opacity stack

        Behavior on opacity {
            Anim {}
        }

        BlobGroup {
            id: blobGroup

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, 1)
            smoothing: 16

            Behavior on color {
                CAnim {}
            }
        }

        // Border frame
        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -root.borderPad
            group: blobGroup
            radius: Tokens.rounding.small
            borderLeft: sidebar.width + 10 + root.borderPad
            borderTop: 10 + root.borderPad
            borderRight: 10 + root.borderPad
            borderBottom: 10 + root.borderPad
        }

        BlobRect {
            id: notchBlob

            anchors.right: parent.right
            group: blobGroup
            implicitWidth: closeBtn.width + maximizeBtn.width
            implicitHeight: closeBtn.height
            bottomLeftRadius: Tokens.rounding.small
            deformScale: 0
        }

        BlobRect {
            id: flyoutBlob

            group: blobGroup
            x: flyout.x
            y: flyout.y
            implicitWidth: flyout.drawerWidth
            implicitHeight: flyout.drawerHeight
            radius: Tokens.rounding.small
            // topLeftRadius: 0
            // bottomLeftRadius: 0
            // topRightRadius: flyout.y <= 0 ? 0 : Tokens.rounding.small
            deformScale: 0.00001
            stiffness: 200
            damping: 16
        }

        BlobRect {
            id: popoutBlob

            group: blobGroup
            x: unifiedPopout.x
            y: unifiedPopout.y
            implicitWidth: unifiedPopout.drawerWidth
            implicitHeight: unifiedPopout.drawerHeight
            visible: session.sidebarCollapsed
            radius: Tokens.rounding.normal
            // topLeftRadius: 0
            // topRightRadius: 0
            // bottomLeftRadius: 0
            deformScale: 0.00001
            stiffness: 200
            damping: 16
        }
    }

    Sidebar {
        id: sidebar

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: session.sidebarCollapsed ? 100 : 250

        session: root.session

        Behavior on implicitWidth {
            Anim {
                type: Anim.DefaultSpatial
            }
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
            font.pointSize: Tokens.font.size.larger
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
            font.pointSize: Tokens.font.size.normal
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

        x: sidebar.width
        y: sidebar.flyoutTop

        onHoverEntered: sidebar.cancelFlyoutClose()
        onHoverExited: sidebar.scheduleFlyoutClose()
        onChildClicked: id => session.setCategory(id)

        Behavior on y {
            enabled: flyout.open

            Anim {
                type: Anim.DefaultSpatial
            }
        }
    }

    Component {
        id: searchComponent

        SearchEngine {
            session: root.session // qmllint disable incompatible-type
        }
    }

    Component {
        id: configComponent

        ConfigSwitcher {
            session: root.session // qmllint disable incompatible-type
        }
    }

    SidebarPopout {
        id: unifiedPopout

        x: sidebar.width
        y: 0
        visible: session.sidebarCollapsed
        touchingTop: true
        extraLeftMargin: root.flyoutOverlapsPopout ? flyout.drawerWidth : 0
        flyoutDrawerWidth: flyout.drawerWidth
        flyoutOpen: flyout.open

        open: session.searchPopoutOpen || session.configPopoutOpen
        popoutType: session.searchPopoutOpen ? "search" : session.configPopoutOpen ? "config" : ""
        popoutWidth: popoutType === "search" ? 280 : 275

        Component.onCompleted: {
            setComponents(searchComponent, configComponent);
        }
    }

    MouseArea {
        x: sidebar.width
        y: 0
        width: parent.width - sidebar.width
        height: parent.height
        z: -1
        visible: session.sidebarCollapsed && (session.searchPopoutOpen || session.configPopoutOpen)

        onClicked: {
            session.searchPopoutOpen = false;
            session.configPopoutOpen = false;
        }
    }
}
