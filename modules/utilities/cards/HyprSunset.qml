import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2
    Layout.fillWidth: true
    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer
    clip: true

    ColumnLayout {
        id: layout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal
            StyledRect {
                implicitWidth: 40; implicitHeight: 40; radius: Appearance.rounding.full
                color: Sunset.active ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
                MaterialIcon {
                    anchors.centerIn: parent
                    text: Sunset.active ? "nightlight" : "wb_sunny"
                    color: Sunset.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                StyledText { text: qsTr("Blue Light Filter") }
                StyledText {
                    text: Sunset.active ? qsTr("%1K").arg(Sunset.temperature) : qsTr("Disabled")
                    color: Colours.palette.m3onSurfaceVariant; font.pointSize: Appearance.font.size.small
                }
            }
            Item {
                Layout.fillWidth: true
            }
            StyledSwitch {
                checked: Sunset.enabled; onToggled: Sunset.enabled = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: Appearance.spacing.normal
            MaterialIcon { text: "schedule"; color: Sunset.autoMode ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant }
            StyledText {
                Layout.fillWidth: true
                text: Sunset.autoMode ? qsTr("Automatic (9PM - 6AM)") : qsTr("Automatic Schedule")
                font.pointSize: Appearance.font.size.small
                color: Sunset.autoMode ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            StyledSwitch { checked: Sunset.autoMode; onToggled: Sunset.autoMode = checked }
        }

        // Temperature Slider Section
        ColumnLayout {
            Layout.fillWidth: true
            visible: Sunset.active
            spacing: Appearance.spacing.small

            RowLayout {
                StyledText {
                    text: "Warm";
                    font.pointSize: Appearance.font.size.smaller;
                    color: Colours.palette.m3onSurfaceVariant
                }
                Item {
                    Layout.fillWidth: true
                }

                StyledText { text: "Cool"; font.pointSize: Appearance.font.size.smaller; color: Colours.palette.m3onSurfaceVariant }
            }

            StyledSlider {
                Layout.fillWidth: true
                implicitHeight: 24

                from: 2500
                to: 7500
                value: Sunset.temperature
                stepSize: 100
                onMoved: Sunset.temperature = value
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
