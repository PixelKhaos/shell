pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
import qs.utils

import Quickshell

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true
    readonly property int size: implicitHeight
    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    property var dragProxyContainer: null
    property bool isDropTarget: false
    property alias indicator: indicator

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size + (hasWindows ? Appearance.padding.small : 0)

    spacing: 0

    StyledText {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: Config.bar.sizes.innerWidth - Appearance.padding.small * 2

        animate: true
        text: {
            const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
            const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
            let displayName = wsName.toString();
            if (Config.bar.workspaces.capitalisation.toLowerCase() === "upper") {
                displayName = displayName.toUpperCase();
            } else if (Config.bar.workspaces.capitalisation.toLowerCase() === "lower") {
                displayName = displayName.toLowerCase();
            }
            const label = Config.bar.workspaces.label || displayName;
            const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
            const activeLabel = Config.bar.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label);
            return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
        }
        color: {
            if (root.isDropTarget) {
                return Colours.palette.m3primary;
            }
            const actuallyOccupied = Hypr.toplevels.values.some(c => c.workspace?.id === root.ws);
            const isActive = root.activeWsId === root.ws;
            return Config.bar.workspaces.occupiedBg || actuallyOccupied || isActive ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2);
        }
        verticalAlignment: Qt.AlignVCenter
    }

    // Drop indicator for empty workspaces
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Config.bar.sizes.innerWidth
        Layout.preferredHeight: Config.bar.sizes.innerWidth
        visible: root.isDropTarget && !root.isOccupied
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: Appearance.padding.small

            radius: Appearance.rounding.small
            color: Colours.palette.m3primary
            opacity: 0.3
            border.width: 2
            border.color: Colours.palette.m3primary
        
            MaterialIcon {
                anchors.centerIn: parent
                text: "add"
                color: Colours.palette.m3primary
                opacity: 0.8
            }
        }
    }

    Loader {
        id: windows

        objectName: "windows"
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: -Config.bar.sizes.innerWidth / 10

        visible: active
        active: root.hasWindows

        sourceComponent: Column {
            spacing: 0

            // Visual drop area spacer at the start 
            Item {
                width: Config.bar.sizes.innerWidth
                height: root.isDropTarget && root.hasWindows ? Config.bar.sizes.innerWidth - Appearance.padding.small * 2 : 0
                visible: height > 0
                
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: Config.bar.sizes.innerWidth - Appearance.padding.small * 2
                    height: parent.height

                    radius: Appearance.rounding.small
                    color: Colours.palette.m3primary
                    opacity: 0.3
                    border.width: 2
                    border.color: Colours.palette.m3primary
                
                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "add"
                        color: Colours.palette.m3primary
                        opacity: 0.8
                    }
                }
            }

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                model: ScriptModel {
                    values: Hypr.toplevels.values.filter(c => c.workspace?.id === root.ws)
                }

                Item {
                    id: iconItem
                    required property var modelData

                    width: Config.bar.sizes.innerWidth
                    height: icon.height

                    MaterialIcon {
                        id: icon

                        anchors.horizontalCenter: parent.horizontalCenter

                        grade: 0
                        text: Icons.getAppCategoryIcon(parent.modelData?.lastIpcObject?.class ?? "", "terminal")
                        color: Colours.palette.m3onSurfaceVariant
                    }


                    MouseArea {
                        id: dragArea

                        anchors.fill: parent
                        preventStealing: true
                        hoverEnabled: true
                        z: isDragging ? -1 : 1000
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        drag.target: null
                        drag.threshold: 3

                        property bool isDragging: false
                        property point dragStart: Qt.point(0, 0)
                        property var targetWorkspace: null
                        property point iconOffset: Qt.point(0, 0)

                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                        onPressed: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                // Right click: start drag
                                mouse.accepted = true;
                                dragStart = Qt.point(mouse.x, mouse.y);
                                iconOffset = Qt.point(mouse.x, mouse.y);
                                isDragging = false;
                                targetWorkspace = null;
                            } else {
                                // Let left clicks pass through to onClicked
                                mouse.accepted = false;
                            }
                        }

                        onPositionChanged: mouse => {
                            // Only handle drag for right mouse button
                            if (pressed && mouse.buttons & Qt.RightButton) {
                                const dx = mouse.x - dragStart.x;
                                const dy = mouse.y - dragStart.y;
                                const distance = Math.sqrt(dx * dx + dy * dy);
                                
                                if (!isDragging && distance > 3) {
                                    isDragging = true;
                                }
                                
                                if (isDragging) {
                                    const parentPos = mapToItem(iconItem.parent, mouse.x, mouse.y);
                                    iconItem.x = parentPos.x - iconOffset.x;
                                    iconItem.y = parentPos.y - iconOffset.y;
                                    updateWorkspaceHighlight(mouse.x, mouse.y);
                                }
                            }
                        }
                        
                        onClicked: mouse => {
                            // Left click: switch to workspace and focus application
                            if (mouse.button === Qt.LeftButton && iconItem.modelData && iconItem.modelData.address) {
                                const wsId = root.ws;
                                if (Hypr.activeWsId !== wsId) {
                                    Hypr.dispatch(`workspace ${wsId}`);
                                }
                                // Focus the window
                                Hypr.dispatch(`focuswindow address:0x${iconItem.modelData.address}`);
                            }
                        }
                        
                        function updateWorkspaceHighlight(mouseX, mouseY) {
                            // Find layout by traversing up the parent chain
                            let current = root.parent;
                            let layout = null;
                            
                            while (current) {
                                if (current.objectName === "layout") {
                                    layout = current;
                                    break;
                                }
                                current = current.parent;
                            }
                            
                            if (!layout) {
                                return;
                            }
                            
                            // Find workspace containing cursor or closest one
                            const layoutPos = mapToItem(layout, mouseX, mouseY);
                            let closestWorkspace = null;
                            let closestDistance = Infinity;
                            
                            // First pass: check if cursor is directly within any workspace bounds
                            for (let i = 0; i < layout.children.length; i++) {
                                const ws = layout.children[i];
                                if (ws && ws.isWorkspace) {
                                    const wsPos = layout.mapFromItem(ws, 0, 0);
                                    const wsTop = wsPos.y;
                                    const wsBottom = wsPos.y + ws.height;
                                    
                                    // Check if cursor Y is within workspace bounds
                                    if (layoutPos.y >= wsTop && layoutPos.y <= wsBottom) {
                                        closestWorkspace = ws;
                                        closestDistance = 0;
                                        break;
                                    }
                                }
                            }
                            
                            // Second pass: if not within any workspace, find closest by center distance
                            if (!closestWorkspace) {
                                for (let i = 0; i < layout.children.length; i++) {
                                    const ws = layout.children[i];
                                    if (ws && ws.isWorkspace) {
                                        const wsPos = layout.mapFromItem(ws, 0, 0);
                                        const centerY = wsPos.y + ws.height / 2;
                                        const distance = Math.abs(layoutPos.y - centerY);
                                        
                                        if (distance < closestDistance) {
                                            closestDistance = distance;
                                            closestWorkspace = ws;
                                        }
                                    }
                                }
                            }
                            
                            // Reset workspaces that are not the closest
                            for (let i = 0; i < layout.children.length; i++) {
                                const ws = layout.children[i];
                                if (ws && ws.isWorkspace && ws !== closestWorkspace) {
                                    if (ws.isDropTarget) {
                                        ws.isDropTarget = false;
                                    }
                                }
                            }
                            
                            // Only highlight if we're reasonably close to a workspace
                            if (closestWorkspace && closestDistance < Config.bar.sizes.innerWidth * 1.5) {
                                closestWorkspace.isDropTarget = true;
                                targetWorkspace = closestWorkspace.ws;
                            } else {
                                targetWorkspace = null;
                            }
                        }

                        onReleased: mouse => {
                            if (mouse.button === Qt.RightButton && isDragging) {
                                let targetWs = null;
                                
                                // First, try using the tracked targetWorkspace from highlighting
                                if (targetWorkspace) {
                                    targetWs = targetWorkspace;
                                } else {
                                    // Fallback: Find which workspace we're over when released
                                    let current = root.parent;
                                    let layout = null;
                                    while (current) {
                                        if (current.objectName === "layout") {
                                            layout = current;
                                            break;
                                        }
                                        current = current.parent;
                                    }
                                    
                                    if (layout) {
                                        // Get mouse position in layout coordinates
                                        const layoutPos = mapToItem(layout, mouse.x, mouse.y);
                                        const workspaceItem = layout.childAt(layoutPos.x, layoutPos.y);
                                        
                                        if (workspaceItem && workspaceItem.isWorkspace) {
                                            targetWs = workspaceItem.ws;
                                        } else {
                                            // If childAt didn't work, try checking all workspaces manually
                                            for (let i = 0; i < layout.children.length; i++) {
                                                const ws = layout.children[i];
                                                if (ws && ws.isWorkspace) {
                                                    const wsPos = mapToItem(ws, mouse.x, mouse.y);
                                                    if (wsPos.x >= 0 && wsPos.x <= ws.width && wsPos.y >= 0 && wsPos.y <= ws.height) {
                                                        targetWs = ws.ws;
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Move window ONLY if we have a valid target workspace from highlighting
                                // This prevents dropping in empty space between workspaces
                                if (targetWs && targetWs !== root.ws && iconItem.modelData && iconItem.modelData.address && targetWorkspace !== null) {
                                    Hypr.dispatch(`movetoworkspace ${targetWs},address:0x${iconItem.modelData.address}`);
                                }
                                
                                // Reset drop target highlighting
                                let current = root.parent;
                                let layout = null;
                                while (current) {
                                    if (current.objectName === "layout") {
                                        layout = current;
                                        break;
                                    }
                                    current = current.parent;
                                }
                                if (layout) {
                                    for (let i = 0; i < layout.children.length; i++) {
                                        const ws = layout.children[i];
                                        if (ws && ws.isWorkspace) {
                                            ws.isDropTarget = false;
                                        }
                                    }
                                }
                                
                                // Reset icon position
                                iconItem.x = 0;
                                iconItem.y = 0;
                                isDragging = false;
                                targetWorkspace = null;
                            }
                        }

                        onCanceled: () => {
                            isDragging = false;
                            iconItem.x = 0;
                            iconItem.y = 0;
                            
                            // Reset drop target highlighting
                            let current = root.parent;
                            let layout = null;
                            while (current) {
                                if (current.objectName === "layout") {
                                    layout = current;
                                    break;
                                }
                                current = current.parent;
                            }
                            if (layout) {
                                for (let i = 0; i < layout.children.length; i++) {
                                    const ws = layout.children[i];
                                    if (ws && ws.isWorkspace) {
                                        ws.isDropTarget = false;
                                    }
                                }
                            }
                        }
                    }

                    Drag.active: dragArea.drag.active
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    Drag.keys: ["application"]
                    Drag.source: iconItem
                    Drag.proposedAction: Qt.MoveAction

                    states: [
                        State {
                            when: dragArea.isDragging
                            PropertyChanges {
                                target: iconItem
                                opacity: 0.4
                                scale: 1.3
                            }
                            PropertyChanges {
                                target: icon
                                restoreEntryValues: false
                                color: Colours.palette.m3primary
                            }
                        },
                        State {
                            when: dragArea.containsMouse && !dragArea.isDragging
                            PropertyChanges {
                                target: iconItem
                                scale: 1.15
                            }
                        }
                    ]

                    Behavior on opacity {
                        Anim {}
                    }

                    Behavior on scale {
                        Anim {}
                    }
                }
            }
        }
    }

    Behavior on Layout.preferredHeight {
        enabled: true
        Anim {
            duration: 200
        }
    }
}
