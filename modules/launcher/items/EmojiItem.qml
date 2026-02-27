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
    required property PersistentProperties visibilities

    implicitWidth: 80
    implicitHeight: 80

    StyledRect {
        id: rect

        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: {
            if (GridView.isCurrentItem) return Colours.layer(Colours.palette.m3surfaceContainer, 3);
            if (mouse.containsMouse) return Colours.layer(Colours.palette.m3surfaceContainer, 2);
            return "transparent";
        }

        Behavior on color { CAnim {} }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                Emojis.copyEmoji(root.modelData);
                root.visibilities.launcher = false;
            }
        }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.smaller

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.modelData.emoji
            font.pointSize: Appearance.font.size.extraLarge * 1.5
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width - Appearance.padding.small * 2
            text: root.modelData.name
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.smaller
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }
    }
}
