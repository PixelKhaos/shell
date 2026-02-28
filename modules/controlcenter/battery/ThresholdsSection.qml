pragma ComponentBehavior: Bound

import ".."
import "../components"
import "." as Power
import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

SectionContainer {
    id: root

    required property var rootItem

    Layout.fillWidth: true
    alignTop: true

    Component.onCompleted: {
        const configThresholds = Config.general.battery.powerManagement.thresholds || [];
        thresholdsModel.clear();
        for (let i = 0; i < configThresholds.length; i++) {
            const t = configThresholds[i];
            thresholdsModel.append({
                level: t.level || 40,
                setPowerProfile: t.setPowerProfile || "",
                setRefreshRate: t.setRefreshRate || "",
                disableAnimations: t.disableAnimations || "",
                disableBlur: t.disableBlur || "",
                disableRounding: t.disableRounding || "",
                disableShadows: t.disableShadows || ""
            });
        }
    }

    function saveThresholds() {
        const thresholds = [];
        for (let i = 0; i < thresholdsModel.count; i++) {
            const item = thresholdsModel.get(i);
            thresholds.push({
                level: item.level,
                setPowerProfile: item.setPowerProfile,
                setRefreshRate: item.setRefreshRate,
                disableAnimations: item.disableAnimations,
                disableBlur: item.disableBlur,
                disableRounding: item.disableRounding,
                disableShadows: item.disableShadows
            });
        }
        Config.general.battery.powerManagement.thresholds = thresholds;
        Config.save();
    }

    ListModel {
        id: thresholdsModel
    }

    StyledText {
        text: qsTr("Battery Level Thresholds")
        font.pointSize: Appearance.font.size.normal
    }

    StyledText {
        text: qsTr("Define actions to take at specific battery levels")
        font.pointSize: Appearance.font.size.smaller
        opacity: 0.7
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Appearance.spacing.normal
        rowSpacing: Appearance.spacing.normal
        
        Behavior on implicitHeight {
            Anim {}
        }

        // Add threshold button (first cell)
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            radius: Appearance.rounding.normal
            color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
            border.width: 2
            border.color: Qt.alpha(Colours.palette.m3primary, 0.3)

            StateLayer {
                function onClicked() {
                    thresholdsModel.append({
                        level: 50,
                        setPowerProfile: "",
                        setRefreshRate: "",
                        disableAnimations: "",
                        disableBlur: "",
                        disableRounding: "",
                        disableShadows: ""
                    });
                    root.saveThresholds();
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.smaller

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "add_circle"
                    font.pointSize: Appearance.font.size.large * 2
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Add Threshold")
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3primary
                }
            }
        }

        // Threshold cards
        Repeater {
            model: thresholdsModel

            delegate: StyledRect {
                required property int index
                required property int level
                required property var setPowerProfile
                required property var setRefreshRate
                required property string disableAnimations
                required property string disableBlur
                required property string disableRounding
                required property string disableShadows

                Layout.fillWidth: true
                Layout.preferredHeight: 150
                radius: Appearance.rounding.normal
                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.smaller

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            Layout.fillWidth: true
                            text: level + "% Battery"
                            font.pointSize: Appearance.font.size.normal
                            font.weight: 500
                        }

                        IconButton {
                            icon: "delete"
                            onClicked: {
                                thresholdsModel.remove(index);
                                root.saveThresholds();
                            }
                        }
                    }

                    StyledText {
                        text: {
                            const parts = [];
                            if (setPowerProfile) parts.push(setPowerProfile);
                            if (disableAnimations !== "" || disableBlur !== "" || disableRounding !== "" || disableShadows !== "") {
                                parts.push("effects configured");
                            }
                            return parts.length > 0 ? parts.join(", ") : qsTr("No actions");
                        }
                        font.pointSize: Appearance.font.size.smaller
                        opacity: 0.7
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Item { Layout.fillHeight: true }

                    TextButton {
                        Layout.alignment: Qt.AlignRight
                        text: qsTr("Edit")
                        onClicked: {
                            // TODO: Open edit dialog
                        }
                    }
                }
            }
        }
    }
}
