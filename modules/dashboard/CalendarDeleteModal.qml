pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import Caelestia
import QtQuick
import QtQuick.Layouts

Loader {
    id: root

    required property var state
    property string eventId: ""
    property string eventTitle: ""
    property bool deleteAll: false

    anchors.fill: parent
    z: 1001

    opacity: root.eventId ? 1 : 0
    active: opacity > 0
    asynchronous: true

    sourceComponent: MouseArea {
        hoverEnabled: true
        onClicked: {
            root.state.calendarDeleteEventId = "";
            root.state.calendarDeleteEventTitle = "";
            root.state.calendarDeleteAllRecurring = false;
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
            anchors.centerIn: parent
            radius: Appearance.rounding.large
            color: Colours.palette.m3surfaceContainerHigh

            scale: 0
            Component.onCompleted: scale = Qt.binding(() => root.eventId ? 1 : 0)

            width: Math.min(parent.width - Appearance.padding.large * 2, 400)
            implicitHeight: contentLayout.implicitHeight + Appearance.padding.large * 3

            MouseArea { anchors.fill: parent }

            Elevation { anchors.fill: parent; radius: parent.radius; z: -1; level: 3 }

            ColumnLayout {
                id: contentLayout

                anchors.fill: parent
                anchors.margins: Appearance.padding.large * 1.5
                spacing: Appearance.spacing.normal

                StyledText {
                    text: root.deleteAll ? qsTr("Delete all recurring events?") : qsTr("Delete event?")
                    font.pointSize: Appearance.font.size.normal * 1.2
                    font.weight: 600
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.deleteAll 
                        ? qsTr("All instances of '%1' will be permanently deleted.").arg(root.eventTitle)
                        : qsTr("'%1' will be permanently deleted.").arg(root.eventTitle)
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.normal * 0.9
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.topMargin: Appearance.spacing.normal
                    Layout.alignment: Qt.AlignRight
                    spacing: Appearance.spacing.normal

                    TextButton {
                        text: qsTr("Cancel")
                        type: TextButton.Text
                        onClicked: {
                            root.state.calendarDeleteEventId = "";
                            root.state.calendarDeleteEventTitle = "";
                            root.state.calendarDeleteAllRecurring = false;
                        }
                    }

                    TextButton {
                        text: qsTr("Delete")
                        type: TextButton.Text
                        onClicked: {
                            if (root.deleteAll) {
                                const event = CalendarEvents.getEvent(root.eventId);
                                if (event?.parentRecurrence) {
                                    CalendarEvents.deleteRecurringSeries(event.parentRecurrence);
                                }
                            } else {
                                CalendarEvents.deleteEvent(root.eventId);
                            }
                            root.state.calendarDeleteEventId = "";
                            root.state.calendarDeleteEventTitle = "";
                            root.state.calendarDeleteAllRecurring = false;
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
