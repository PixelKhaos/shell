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
        onClicked: {
            // Don't close modal if it's open - only close on explicit close button
            // This prevents accidental closes when clicking outside dropdowns
        }

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

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.padding.large
            radius: Appearance.rounding.large
            color: Colours.palette.m3surfaceContainerHigh

            scale: 0
            Component.onCompleted: scale = Qt.binding(() => root.state.calendarEventModalOpen ? 1 : 0)

            width: Math.min(parent.width - Appearance.padding.large * 2, 620)
            implicitHeight: contentLayout.implicitHeight + Appearance.padding.large * 2

            MouseArea { anchors.fill: parent }

            Elevation { anchors.fill: parent; radius: parent.radius; z: -1; level: 3 }

            ColumnLayout {
                id: contentLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 1.5
                spacing: Appearance.spacing.large

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    StyledText {
                        Layout.fillWidth: true
                        text: modal.isEdit ? qsTr("Edit Event") : qsTr("Add Event")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 600
                    }

                    MouseArea {
                        implicitWidth: 32
                        implicitHeight: 32
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.state.calendarEventModalOpen = false

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.large
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: titleField.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.normal
                    color: Colours.palette.m3surfaceContainer

                    StyledTextField {
                        id: titleField

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        placeholderText: qsTr("Event title")
                        text: modal.event?.title ?? ""

                        Component.onCompleted: forceActiveFocus()
                    }
                }

                // Time pickers
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.extraLarge

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("Start time")
                            font.pointSize: Appearance.font.size.normal * 0.9
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            TimeSpinBox {
                                id: startHour
                                Layout.preferredWidth: 50
                                max: 23
                                value: {
                                    const date = modal.event ? new Date(modal.event.start) : new Date();
                                    return date.getHours();
                                }
                                onValueModified: value => startHour.value = value
                            }

                            StyledText {
                                text: ":"
                                font.pointSize: Appearance.font.size.large
                                font.weight: 600
                            }

                            TimeSpinBox {
                                id: startMinute
                                Layout.preferredWidth: 50
                                max: 59
                                value: {
                                    const date = modal.event ? new Date(modal.event.start) : new Date();
                                    return date.getMinutes();
                                }
                                onValueModified: value => startMinute.value = value
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

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            TimeSpinBox {
                                id: endHour
                                Layout.preferredWidth: 50
                                max: 23
                                value: {
                                    const date = modal.event ? new Date(modal.event.end) : new Date(new Date().getTime() + 3600000);
                                    return date.getHours();
                                }
                                onValueModified: value => endHour.value = value
                            }

                            StyledText {
                                text: ":"
                                font.pointSize: Appearance.font.size.large
                                font.weight: 600
                            }

                            TimeSpinBox {
                                id: endMinute
                                Layout.preferredWidth: 50
                                max: 59
                                value: {
                                    const date = modal.event ? new Date(modal.event.end) : new Date(new Date().getTime() + 3600000);
                                    return date.getMinutes();
                                }
                                onValueModified: value => endMinute.value = value
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: locationField.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.normal
                    color: Colours.palette.m3surfaceContainer

                    StyledTextField {
                        id: locationField

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        placeholderText: qsTr("Location (optional)")
                        text: modal.event?.location ?? ""
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: descriptionField.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.normal
                    color: Colours.palette.m3surfaceContainer

                    StyledTextField {
                        id: descriptionField

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        placeholderText: qsTr("Description (optional)")
                        text: modal.event?.description ?? ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Reminder")
                        font.pointSize: Appearance.font.size.normal * 0.9
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    ButtonGroup {
                        id: reminderGroup
                        buttons: [reminder0, reminder5, reminder15, reminder30, reminder60, reminder1440]
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledRadioButton {
                            id: reminder0
                            text: qsTr("None")
                            property int value: 0
                        }

                        StyledRadioButton {
                            id: reminder5
                            text: qsTr("5 min")
                            property int value: 300
                        }

                        StyledRadioButton {
                            id: reminder15
                            text: qsTr("15 min")
                            property int value: 900
                            checked: true
                        }

                        StyledRadioButton {
                            id: reminder30
                            text: qsTr("30 min")
                            property int value: 1800
                        }

                        StyledRadioButton {
                            id: reminder60
                            text: qsTr("1 hour")
                            property int value: 3600
                        }

                        StyledRadioButton {
                            id: reminder1440
                            text: qsTr("1 day")
                            property int value: 86400
                        }
                    }

                    Component.onCompleted: {
                        if (modal.event?.reminders && modal.event.reminders.length > 0) {
                            const savedValue = modal.event.reminders[0].offset;
                            [reminder0, reminder5, reminder15, reminder30, reminder60, reminder1440].forEach(btn => {
                                if (btn.value === savedValue) btn.checked = true;
                            });
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Repeat")
                        font.pointSize: Appearance.font.size.normal * 0.9
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    ButtonGroup {
                        id: repeatGroup
                        buttons: [repeatNever, repeatDaily, repeatWeekly, repeatBiweekly, repeatMonthly, repeatCustom]
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledRadioButton {
                            id: repeatNever
                            text: qsTr("Never")
                            property string value: "never"
                            checked: true
                        }

                        StyledRadioButton {
                            id: repeatDaily
                            text: qsTr("Daily")
                            property string value: "daily"
                        }

                        StyledRadioButton {
                            id: repeatWeekly
                            text: qsTr("Weekly")
                            property string value: "weekly"
                        }

                        StyledRadioButton {
                            id: repeatBiweekly
                            text: qsTr("Biweekly")
                            property string value: "biweekly"
                        }

                        StyledRadioButton {
                            id: repeatMonthly
                            text: qsTr("Monthly")
                            property string value: "monthly"
                        }

                        StyledRadioButton {
                            id: repeatCustom
                            text: qsTr("Custom...")
                            property string value: "custom"
                        }
                    }
                }

                // Custom repeat options
                RowLayout {
                    Layout.fillWidth: true
                    visible: repeatCustom.checked
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: qsTr("Every")
                        font.pointSize: Appearance.font.size.normal * 0.9
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    CustomSpinBox {
                        id: customRepeatInterval
                        Layout.preferredWidth: 150
                        min: 1
                        max: 365
                        value: 1
                        onValueModified: value => customRepeatInterval.value = value
                    }

                    ComboBox {
                        id: customRepeatUnit
                        Layout.fillWidth: true
                        model: [
                            { text: qsTr("days"), value: "days" },
                            { text: qsTr("weeks"), value: "weeks" },
                            { text: qsTr("months"), value: "months" }
                        ]
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: 0
                    }
                }

                RowLayout {
                    Layout.topMargin: Appearance.spacing.normal
                    Layout.bottomMargin: Appearance.spacing.small
                    Layout.alignment: Qt.AlignRight
                    spacing: Appearance.spacing.normal

                    TextButton {
                        text: qsTr("Cancel")
                        type: TextButton.Text
                        onClicked: root.state.calendarEventModalOpen = false
                    }

                    Item { Layout.fillWidth: true }

                    TextButton {
                        text: modal.event?.isRecurringInstance ? qsTr("Delete All") : ""
                        type: TextButton.Text
                        visible: modal.isEdit && modal.event?.isRecurringInstance
                        onClicked: {
                            root.state.calendarDeleteAllRecurring = true;
                            root.state.calendarDeleteEventId = root.eventId;
                            root.state.calendarDeleteEventTitle = modal.event?.title ?? "";
                        }
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
                            // Build date/time from spin boxes
                            const baseDate = new Date(root.prefilledDate);
                            baseDate.setHours(0, 0, 0, 0);
                            
                            const startDateTime = new Date(baseDate);
                            startDateTime.setHours(startHour.value, startMinute.value, 0, 0);
                            
                            const endDateTime = new Date(baseDate);
                            endDateTime.setHours(endHour.value, endMinute.value, 0, 0);
                            
                            // Get selected reminder value
                            const selectedReminder = reminderGroup.checkedButton;
                            const reminders = selectedReminder && selectedReminder.value > 0
                                ? [{ offset: selectedReminder.value, type: "notification" }]
                                : [];

                            // Build recurrence object
                            let recurrence = null;
                            const selectedRepeat = repeatGroup.checkedButton;
                            if (selectedRepeat && selectedRepeat.value !== "never") {
                                if (selectedRepeat.value === "custom") {
                                    recurrence = {
                                        type: "custom",
                                        interval: customRepeatInterval.value,
                                        unit: customRepeatUnit.currentValue
                                    };
                                } else {
                                    recurrence = {
                                        type: selectedRepeat.value
                                    };
                                }
                            }

                            if (modal.isEdit) {
                                CalendarEvents.updateEvent(root.eventId, {
                                    title: titleField.text.trim(),
                                    start: startDateTime.toISOString(),
                                    end: endDateTime.toISOString(),
                                    location: locationField.text.trim(),
                                    description: descriptionField.text.trim(),
                                    reminders: reminders,
                                    recurrence: recurrence
                                });
                            } else {
                                CalendarEvents.createEvent(
                                    titleField.text.trim(),
                                    startDateTime.toISOString(),
                                    endDateTime.toISOString(),
                                    descriptionField.text.trim(),
                                    locationField.text.trim(),
                                    "#2196F3",
                                    reminders,
                                    recurrence
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
