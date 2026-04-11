pragma Singleton

import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    function create(parent, props) {
        nexusWindow.createObject(parent ?? dummy, props);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusWindow

        FloatingWindow {
            id: win

            property alias active: nexus.active
            property alias sidebarCollapsed: nexus.sidebarCollapsed

            color: Colours.tPalette.m3surface

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: implicitWidth
            minimumSize.height: implicitHeight
            maximumSize.width: implicitWidth
            maximumSize.height: implicitHeight

            title: qsTr("Nexus - %1").arg(nexus.active.slice(0, 1).toUpperCase() + nexus.active.slice(1))

            Nexus {
                id: nexus

                anchors.fill: parent
                screen: win.screen
                onClose: win.destroy()
                floating: true
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
