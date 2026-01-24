pragma ComponentBehavior: Bound

import "../services"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var modelData
    required property int index
    required property PersistentProperties visibilities

    implicitHeight: rect.implicitHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    StyledRect {
        id: rect

        anchors.fill: parent
        implicitHeight: content.implicitHeight + Appearance.padding.normal * 2
        radius: Appearance.rounding.normal
        color: {
            if (ListView.isCurrentItem) return Colours.layer(Colours.palette.m3surfaceContainer, 3);
            if (mouse.containsMouse) return Colours.layer(Colours.palette.m3surfaceContainer, 2);
            return "transparent";
        }

        Behavior on color { CAnim {} }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: {
                if (containsMouse) {
                    root.ListView.view.hoveredItem = root;
                    root.ListView.view.lastInteraction = "hover";
                } else if (root.ListView.view.hoveredItem === root) {
                    root.ListView.view.hoveredItem = null;
                }
            }
            onClicked: {
                root.ListView.view.currentIndex = index;
                Clipboard.copyToClipboard(root.modelData);
                root.visibilities.launcher = false;
            }
        }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: {
                if (root.modelData.isPinned) return "push_pin";
                if (root.modelData.isImage) return "image";
                return "description";
            }
            color: root.modelData.isPinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.large
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.smaller

            StyledText {
                Layout.fillWidth: true
                text: root.modelData.content
                color: ListView.isCurrentItem ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
                elide: Text.ElideRight
            }

            StyledText {
                text: {
                    const content = root.modelData.content;
                    const words = content.split(/\s+/).length;
                    const chars = content.length;
                    return qsTr("%1 characters, %2 words").arg(chars).arg(words);
                }
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }
        }

        Row {
            id: buttonsRow
            spacing: Appearance.spacing.small

            IconButton {
                icon: root.modelData.isPinned ? "push_pin" : "keep"
                type: root.modelData.isPinned ? IconButton.Filled : IconButton.Text
                radius: Appearance.rounding.small
                padding: Appearance.padding.small
                onClicked: {
                    Clipboard.togglePin(root.modelData);
                }
            }

            IconButton {
                icon: "delete"
                type: IconButton.Text
                radius: Appearance.rounding.small
                padding: Appearance.padding.small
                onClicked: {
                    root.ListView.view.deletedItemIndex = root.index;
                    Clipboard.deleteItem(root.modelData);
                }
            }
        }
    }
    }
}
