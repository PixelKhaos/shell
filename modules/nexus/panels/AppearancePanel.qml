pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

Item {
    id: root

    property int activeTabIndex: 0

    StackLayout {
        anchors.fill: parent
        currentIndex: root.activeTabIndex

        // Wallpaper & Scheme
        ColumnLayout {
            anchors.centerIn: parent
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.normal

            StyledText {
                text: "Wallpaper & Scheme"
                font.pointSize: Appearance.font.size.larger
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: "Theme mode, color scheme, and wallpaper settings"
                font.pointSize: Appearance.font.size.normal
                color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
            }
        }

        // Typography & Motion
        ColumnLayout {
            anchors.centerIn: parent
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.normal

            StyledText {
                text: "Typography & Motion"
                font.pointSize: Appearance.font.size.larger
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: "Font and animation settings"
                font.pointSize: Appearance.font.size.normal
                color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
            }
        }

        // Effects
        ColumnLayout {
            anchors.centerIn: parent
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.normal

            StyledText {
                text: "Effects"
                font.pointSize: Appearance.font.size.larger
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: "Shadows, rounding, and visual effects"
                font.pointSize: Appearance.font.size.normal
                color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
            }
        }
    }
}
