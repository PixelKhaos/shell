import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset
    property var dragProxyContainer: null

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: implicitHeight + (hasWindows ? Appearance.padding.small : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    DropArea {
        id: dropArea
        objectName: "dropArea"

        anchors.fill: parent
        property int targetWorkspace: root.ws
        keys: ["application"]

        onEntered: drag => {
            if (drag.source && drag.source.modelData) {
                indicator.color = Colours.palette.m3primary;
            }
        }

        onExited: {
            indicator.color = Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2);
        }

        onDropped: drop => {
            if (drop.source && drop.source.modelData && drop.source.modelData.address) {
                const targetWs = root.ws;
                const sourceWs = drop.source.modelData.workspace?.id;
                if (targetWs !== sourceWs) {
                    Hypr.dispatch(`movetoworkspace ${targetWs},address:0x${drop.source.modelData.address}`);
                }
            }
        }
    }

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
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
        verticalAlignment: Qt.AlignVCenter
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

                    width: icon.width
                    height: icon.height

                    MaterialIcon {
                        id: icon

                        grade: 0
                        text: Icons.getAppCategoryIcon(parent.modelData.lastIpcObject.class, "terminal")
                        color: Colours.palette.m3onSurfaceVariant
                    }


                    MouseArea {
                        id: dragArea

                        anchors.fill: parent
                        preventStealing: true
                        hoverEnabled: true
                        z: 1000
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        drag.target: iconItem
                        drag.threshold: 3

                        property bool isDragging: false
                        property point dragStart: Qt.point(0, 0)
                        property var targetWorkspace: null

                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                        onPressed: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                // Right click: start drag
                                mouse.accepted = true;
                                dragStart = Qt.point(mouse.x, mouse.y);
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
                            
                            if (!layout) return;
                            
                            // Reset all workspace indicators
                            for (let i = 0; i < layout.children.length; i++) {
                                const ws = layout.children[i];
                                if (ws && ws.isWorkspace && ws.indicator) {
                                    const isOccupied = root.occupied[ws.ws] ?? false;
                                    const activeWsId = root.activeWsId;
                                    ws.indicator.color = Config.bar.workspaces.occupiedBg || isOccupied || activeWsId === ws.ws ? 
                                        Colours.palette.m3onSurface : 
                                        Colours.layer(Colours.palette.m3outlineVariant, 2);
                                }
                            }
                            
                            // Highlight workspace under mouse
                            const layoutPos = mapToItem(layout, mouseX, mouseY);
                            const workspaceItem = layout.childAt(layoutPos.x, layoutPos.y);
                            if (workspaceItem && workspaceItem.isWorkspace && workspaceItem.indicator) {
                                workspaceItem.indicator.color = Colours.palette.m3primary;
                                targetWorkspace = workspaceItem.ws;
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
                                
                                // Move window if we have a valid target workspace
                                if (targetWs && targetWs !== root.ws && iconItem.modelData && iconItem.modelData.address) {
                                    Hypr.dispatch(`movetoworkspace ${targetWs},address:0x${iconItem.modelData.address}`);
                                }
                                
                                // Reset highlighting
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
                                        if (ws && ws.isWorkspace && ws.indicator) {
                                            const isOccupied = root.occupied[ws.ws] ?? false;
                                            const activeWsId = root.activeWsId;
                                            ws.indicator.color = Config.bar.workspaces.occupiedBg || isOccupied || activeWsId === ws.ws ? 
                                                Colours.palette.m3onSurface : 
                                                Colours.layer(Colours.palette.m3outlineVariant, 2);
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

                        onCanceled: {
                            iconItem.x = 0;
                            iconItem.y = 0;
                            isDragging = false;
                            targetWorkspace = null;
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
        Anim {}
    }
}
