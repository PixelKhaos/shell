pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import Caelestia
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

Loader {
    id: root

    required property var state
    property string eventId: ""
    property date prefilledDate: new Date()

    anchors.fill: parent
    z: 1000

    opacity: state.calendarEventModalOpen ? 1 : 0
    active: opacity > 0
    asynchronous: true

    sourceComponent: MouseArea {
        id: modal

        readonly property var event: root.eventId ? CalendarEvents.getEvent(root.eventId) : null
        readonly property bool isEdit: root.eventId !== ""

        hoverEnabled: true
        onClicked: root.state.calendarEventModalOpen = false

        Item {
            anchors.fill: parent
            anchors.margins: -Appearance.padding.large
            opacity: 0.5

            StyledRect {
                anchors.fill: parent
                color: Colours.palette.m3scrim
            }
        }

        StyledRect {
            id: dialog

            anchors.centerIn: parent
            radius: Appearance.rounding.large
            color: Colours.palette.m3surfaceContainerHigh

            scale: 0
            Component.onCompleted: scale = Qt.binding(() => root.state.calendarEventModalOpen ? 1 : 0)

            width: Math.min(parent.width - Appearance.padding.large * 2, 500)
            implicitHeight: contentLayout.implicitHeight + Appearance.padding.large * 3

            MouseArea { anchors.fill: parent }

            Elevation { anchors.fill: parent; radius: parent.radius; z: -1; level: 3 }

            ColumnLayout {
                id: contentLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 1.5
                spacing: Appearance.spacing.normal

                StyledText {
                    text: modal.isEdit ? qsTr("Edit Event") : qsTr("Add Event")
                    font.pointSize: Appearance.font.size.normal * 1.2
                    font.weight: 600
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Title")
                        font.pointSize: Appearance.font.size.normal * 0.9
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledTextField {
                        id: titleField

                        Layout.fillWidth: true
                        placeholderText: qsTr("Event title")
                        text: modal.event?.title ?? ""

                        Component.onCompleted: forceActiveFocus()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("Start time")
                            font.pointSize: Appearance.font.size.normal * 0.9
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledTextField {
                            id: startTimeField

                            Layout.fillWidth: true
                            placeholderText: "HH:MM"
                            text: {
                                const date = modal.event ? new Date(modal.event.start) : new Date();
                                return Qt.formatTime(date, "HH:mm");
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("End time")
                            font.pointSize: Appearance.font.size.normal * 0.9
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledTextField {
                            id: endTimeField

                            Layout.fillWidth: true
                            placeholderText: "HH:MM"
                            text: {
                                const date = modal.event ? new Date(modal.event.end) : new Date(new Date().getTime() + 3600000);
                                return Qt.formatTime(date, "HH:mm");
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Location (optional)")
                        font.pointSize: Appearance.font.size.normal * 0.9
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledTextField {
                        id: locationField

                        Layout.fillWidth: true
                        placeholderText: qsTr("Add location")
                        text: modal.event?.location ?? ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Description (optional)")
                        font.pointSize: Appearance.font.size.normal * 0.9
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledTextField {
                        id: descriptionField

                        Layout.fillWidth: true
                        placeholderText: qsTr("Add description")
                        text: modal.event?.description ?? ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Remind me")
                        font.pointSize: Appearance.font.size.normal * 0.9
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    ComboBox {
                        id: reminderCombo

                        Layout.fillWidth: true
                        model: [
                            { text: qsTr("No reminder"), value: 0 },
                            { text: qsTr("5 minutes before"), value: 300 },
                            { text: qsTr("15 minutes before"), value: 900 },
                            { text: qsTr("30 minutes before"), value: 1800 },
                            { text: qsTr("1 hour before"), value: 3600 },
                            { text: qsTr("1 day before"), value: 86400 }
                        ]
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: 2 // Default to 15 minutes
                    }
                }

                RowLayout {
                    Layout.topMargin: Appearance.spacing.normal
                    Layout.alignment: Qt.AlignRight
                    spacing: Appearance.spacing.normal

                    TextButton {
                        text: qsTr("Cancel")
                        type: TextButton.Text
                        onClicked: root.state.calendarEventModalOpen = false
                    }

                    TextButton {
                        text: modal.isEdit ? qsTr("Delete") : ""
                        type: TextButton.Text
                        visible: modal.isEdit
                        onClicked: {
                            root.state.calendarDeleteEventId = root.eventId;
                            root.state.calendarDeleteEventTitle = modal.event?.title ?? "";
                        }
                    }

                    TextButton {
                        text: modal.isEdit ? qsTr("Save") : qsTr("Add")
                        type: TextButton.Filled
                        enabled: titleField.text.trim() !== ""
                        onClicked: {
                            const dateStr = Qt.formatDate(root.prefilledDate, "yyyy-MM-dd");
                            const startDateTime = new Date(dateStr + "T" + startTimeField.text);
                            const endDateTime = new Date(dateStr + "T" + endTimeField.text);
                            
                            const reminders = reminderCombo.currentValue > 0 
                                ? [{ offset: reminderCombo.currentValue, type: "toast" }]
                                : [];

                            if (modal.isEdit) {
                                CalendarEvents.updateEvent(root.eventId, {
                                    title: titleField.text.trim(),
                                    start: startDateTime.toISOString(),
                                    end: endDateTime.toISOString(),
                                    location: locationField.text.trim(),
                                    description: descriptionField.text.trim(),
                                    reminders: reminders
                                });
                            } else {
                                CalendarEvents.createEvent(
                                    titleField.text.trim(),
                                    startDateTime.toISOString(),
                                    endDateTime.toISOString(),
                                    descriptionField.text.trim(),
                                    locationField.text.trim(),
                                    "#2196F3",
                                    reminders
                                );
                            }

                            root.state.calendarEventModalOpen = false;
                        }
                    }
                }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }

    Behavior on opacity { Anim {} }
}
