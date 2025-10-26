pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property int value
    property int max: 99
    property int min: 0

    signal valueModified(value: int)

    spacing: 0

    StyledRect {
        Layout.preferredWidth: 50
        Layout.preferredHeight: 24
        radius: Appearance.rounding.small
        color: Colours.palette.m3primary

        StateLayer {
            id: upState
            color: Colours.palette.m3onPrimary

            function onClicked(): void {
                root.valueModified(Math.min(root.max, root.value + 1));
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: "keyboard_arrow_up"
            color: Colours.palette.m3onPrimary
            font.pointSize: Appearance.font.size.normal
        }
    }

    StyledRect {
        Layout.preferredWidth: 50
        implicitHeight: textField.implicitHeight + Appearance.padding.small * 2
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainer

        StyledTextField {
            id: textField
            anchors.fill: parent
            anchors.margins: Appearance.padding.tiny
            horizontalAlignment: Text.AlignHCenter
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            text: root.value.toString().padStart(2, '0')
            onAccepted: {
                const newValue = parseInt(text);
                if (!isNaN(newValue)) {
                    root.valueModified(Math.max(root.min, Math.min(root.max, newValue)));
                }
            }
        }
    }

    StyledRect {
        Layout.preferredWidth: 50
        Layout.preferredHeight: 24
        radius: Appearance.rounding.small
        color: Colours.palette.m3primary

        StateLayer {
            id: downState
            color: Colours.palette.m3onPrimary

            function onClicked(): void {
                root.valueModified(Math.max(root.min, root.value - 1));
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: "keyboard_arrow_down"
            color: Colours.palette.m3onPrimary
            font.pointSize: Appearance.font.size.normal
        }
    }
}
