pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property date selectedDate
    signal backToMonth()
    signal addEvent()
    signal editEvent(string eventId)

    readonly property var events: CalendarEvents.getEventsForDate(selectedDate)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Item {
                implicitWidth: implicitHeight
                implicitHeight: backIcon.implicitHeight + Appearance.padding.small * 2

                StateLayer {
                    radius: Appearance.rounding.full

                    function onClicked(): void {
                        root.backToMonth();
                    }
                }

                MaterialIcon {
                    id: backIcon

                    anchors.centerIn: parent
                    text: "chevron_left"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 700
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Qt.formatDate(root.selectedDate, "MMMM d, yyyy")
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
                font.capitalization: Font.Capitalize
            }

            Item {
                implicitWidth: implicitHeight
                implicitHeight: addIcon.implicitHeight + Appearance.padding.small * 2

                StateLayer {
                    radius: Appearance.rounding.full

                    function onClicked(): void {
                        root.addEvent();
                    }
                }

                MaterialIcon {
                    id: addIcon

                    anchors.centerIn: parent
                    text: "add"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 700
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 100

            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: Appearance.spacing.large

                Repeater {
                    model: root.events

                    delegate: Item {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: eventContent.implicitHeight + Appearance.padding.normal * 2

                        RowLayout {
                            id: eventContent

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Appearance.padding.normal
                            spacing: Appearance.spacing.normal

                            Rectangle {
                                Layout.preferredWidth: 4
                                Layout.preferredHeight: timeColumn.implicitHeight
                                radius: 2
                                color: Colours.palette.m3primary
                            }

                            ColumnLayout {
                                id: timeColumn
                                Layout.fillWidth: true
                                spacing: Appearance.spacing.small

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    font.pointSize: Appearance.font.size.normal
                                    font.weight: 600
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    text: {
                                        const start = new Date(modelData.start);
                                        const end = new Date(modelData.end);
                                        return Qt.formatTime(start, "HH:mm") + " - " + Qt.formatTime(end, "HH:mm");
                                    }
                                    color: Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Appearance.font.size.normal * 0.9
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: modelData.location
                                    text: modelData.location || ""
                                    color: Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Appearance.font.size.normal * 0.9
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: modelData.description
                                    text: modelData.description || ""
                                    color: Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Appearance.font.size.normal * 0.9
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                }
                            }

                            MouseArea {
                                id: editArea
                                Layout.preferredWidth: editIcon.implicitWidth + Appearance.padding.small * 2
                                Layout.preferredHeight: editIcon.implicitHeight + Appearance.padding.small * 2
                                Layout.alignment: Qt.AlignTop
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.editEvent(modelData.id)

                                MaterialIcon {
                                    id: editIcon
                                    anchors.centerIn: parent
                                    text: "edit"
                                    font.pointSize: Appearance.font.size.normal

                                    color: {
                                        return editArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant;
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Appearance.anim.durations.small
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    visible: root.events.length === 0
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "event"
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.large * 2
                        opacity: 0.3
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No events")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.normal
                        opacity: 0.6
                    }
                }
            }
        }
    }
}
