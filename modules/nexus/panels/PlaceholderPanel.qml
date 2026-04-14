pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

Item {
    id: root

    property int activeTabIndex: 0

    StackLayout {
        anchors.fill: parent
        currentIndex: root.activeTabIndex

        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "construction"
                    font.pointSize: Appearance.font.size.extraLarge
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.3)
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Panel not yet implemented")
                    font.pointSize: Appearance.font.size.larger
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("This settings page will be available in a future update.")
                    font.pointSize: Appearance.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.35)
                }
            }
        }

        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Second tab placeholder")
                    font.pointSize: Appearance.font.size.larger
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }
            }
        }
    }
}
