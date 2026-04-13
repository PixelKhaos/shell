pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import ".."

ColumnLayout {
    id: root

    required property NexusSession session

    spacing: Appearance.spacing.small

    readonly property var configModel: {
        const items = [{ id: "global", label: "Global", icon: "language", desc: "Settings apply everywhere" }];
        for (const screen of Screens.screens) {
            items.push({
                id: screen.name,
                label: screen.name,
                icon: "monitor",
                desc: "Monitor-specific overrides"
            });
        }
        return items;
    }

    StyledText {
        text: "Editing Context"
        font.pointSize: Appearance.font.size.small
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
    }

    // Divider
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    }

    Repeater {
        model: root.configModel

        delegate: Item {
            id: configDelegate
            required property var modelData

            Layout.fillWidth: true
            Layout.preferredHeight: 48

            readonly property bool isActive: root.session.activeConfig === modelData.id

            StyledRect {
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: configDelegate.isActive ? Qt.alpha(Colours.palette.m3primary, 0.12) : "transparent"

                Behavior on color {
                    CAnim {}
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.spacing.normal
                    anchors.rightMargin: Appearance.spacing.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: configDelegate.modelData.icon
                        font.pointSize: Appearance.font.size.larger
                        color: configDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        fill: configDelegate.isActive ? 1 : 0

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: configDelegate.modelData.label
                            font.pointSize: Appearance.font.size.normal
                            font.weight: Font.Medium
                            color: configDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        StyledText {
                            text: configDelegate.modelData.desc
                            font.pointSize: Appearance.font.size.small - 1
                            color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                        }
                    }

                    MaterialIcon {
                        visible: configDelegate.isActive
                        text: "check"
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3primary
                    }
                }

                StateLayer {
                    function onClicked() {
                        root.session.activeConfig = configDelegate.modelData.id;
                        root.session.configPopoutOpen = false;
                    }
                    radius: parent.radius
                    color: Colours.palette.m3onSurface
                }
            }
        }
    }
}
