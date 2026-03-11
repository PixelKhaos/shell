pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Appearance.padding.normal : Appearance.padding.small
    readonly property int spacing: Config.bar.tray.background ? Appearance.spacing.small : 0

    property bool expanded

    readonly property real nonAnimHeight: {
        if (!Config.bar.tray.compact)
            return layout.implicitHeight + padding * 2;
        return (expanded ? layout.implicitHeight : layout.pinnedHeight) + expandIcon.implicitHeight + spacing + padding * 2;
    }

    clip: true
    visible: height > 0

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: nonAnimHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Appearance.rounding.full

    Column {
        id: layout

        property real pinnedHeight: {
            let height = 0;
            for (let i = 0; i < items.count; i++) {
                const item = items.itemAt(i);
                if (item && item.isPinned) {
                    height += item.implicitHeight;
                    if (height > 0)
                        height += spacing;
                }
            }
            return height > 0 ? height - spacing : 0;
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.padding
        spacing: Appearance.spacing.small

        add: Transition {
            Anim {
                properties: "opacity"
                from: 0
                to: 1
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: {
                    const filtered = SystemTray.items.values.filter(i => !Config.bar.tray.hiddenIcons.includes(i.id));
                    const pinned = filtered.filter(i => Config.bar.tray.pinnedIcons.includes(i.id));
                    const unpinned = filtered.filter(i => !Config.bar.tray.pinnedIcons.includes(i.id));
                    return pinned.concat(unpinned);
                }
            }

            Item {
                required property var modelData
                readonly property bool isPinned: Config.bar.tray.pinnedIcons.includes(modelData.id)
                readonly property bool shouldShow: root.expanded || !Config.bar.tray.compact || isPinned

                implicitWidth: trayItem.implicitWidth
                implicitHeight: trayItem.implicitHeight
                visible: shouldShow || trayItem.opacity > 0
                clip: true

                TrayItem {
                    id: trayItem
                    anchors.centerIn: parent
                    modelData: parent.modelData
                    opacity: parent.shouldShow ? 1 : 0
                    scale: parent.shouldShow ? 1 : 0.5
                    transformOrigin: Item.Center

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.anim.durations.small
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Appearance.anim.durations.small
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: expandIcon

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: expandIconInner.implicitWidth
            implicitHeight: expandIconInner.implicitHeight - Appearance.padding.small * 2

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Config.bar.tray.background ? Appearance.padding.small : -Appearance.padding.small
                text: "expand_less"
                font.pointSize: Appearance.font.size.large
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }
}
