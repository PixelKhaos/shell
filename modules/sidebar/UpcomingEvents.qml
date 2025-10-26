pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    anchors.fill: parent

    readonly property var upcomingEvents: CalendarEvents.getUpcomingEvents(7) // Next 7 days
    readonly property int eventsPerPage: 3
    property int currentPage: 0
    readonly property int totalPages: Math.ceil(upcomingEvents.length / eventsPerPage)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: Appearance.spacing.small

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            MaterialIcon {
                text: "event"
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.normal
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Upcoming Events")
                font.pointSize: Appearance.font.size.normal
                font.weight: 600
                color: Colours.palette.m3onSurface
            }

            StyledText {
                visible: root.upcomingEvents.length > 0
                text: `${root.upcomingEvents.length}`
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // Events list
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.small

            Repeater {
                model: {
                    if (root.upcomingEvents.length === 0) return [];
                    const start = root.currentPage * root.eventsPerPage;
                    const end = Math.min(start + root.eventsPerPage, root.upcomingEvents.length);
                    return root.upcomingEvents.slice(start, end);
                }

                delegate: StyledRect {
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: eventContent.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: parent.color = Colours.palette.m3surfaceContainer
                        onExited: parent.color = Colours.palette.m3surfaceContainerHighest

                        onClicked: {
                            // Open event in calendar or show details
                            if (modelData.location && isUrl(modelData.location)) {
                                openLocation(modelData.location);
                            }
                        }
                    }

                    ColumnLayout {
                        id: eventContent

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        spacing: Appearance.spacing.tiny

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.title
                                font.pointSize: Appearance.font.size.normal
                                font.weight: 500
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: {
                                    const eventDate = new Date(modelData.start);
                                    return Qt.formatTime(eventDate, "HH:mm");
                                }
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: {
                                const eventDate = new Date(modelData.start);
                                const today = new Date();
                                today.setHours(0, 0, 0, 0);
                                const evDate = new Date(eventDate);
                                evDate.setHours(0, 0, 0, 0);
                                
                                const diffDays = Math.floor((evDate - today) / 86400000);
                                
                                if (diffDays === 0) return qsTr("Today");
                                if (diffDays === 1) return qsTr("Tomorrow");
                                return Qt.formatDate(eventDate, "ddd, MMM d");
                            }
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3primary
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: modelData.location !== ""
                            spacing: Appearance.spacing.tiny

                            MaterialIcon {
                                text: isUrl(modelData.location) ? "link" : "place"
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.location
                                font.pointSize: Appearance.font.size.small
                                color: isUrl(modelData.location) ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.upcomingEvents.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "event_available"
                        font.pointSize: Appearance.font.size.extraLarge
                        color: Colours.palette.m3onSurfaceVariant
                        opacity: 0.5
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No upcoming events")
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        // Pagination
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.tiny
            visible: root.totalPages > 1
            spacing: Appearance.spacing.small

            Item { Layout.fillWidth: true }

            Repeater {
                model: root.totalPages

                delegate: StyledRect {
                    required property int index

                    implicitWidth: 6
                    implicitHeight: 6
                    radius: 3
                    color: index === root.currentPage 
                        ? Colours.palette.m3primary 
                        : Colours.palette.m3onSurfaceVariant
                    opacity: index === root.currentPage ? 1 : 0.3

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentPage = index
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    function isUrl(location) {
        return location && (location.startsWith('http://') || 
                           location.startsWith('https://') ||
                           location.startsWith('discord://'));
    }
    
    function openLocation(location) {
        // Use Qt.openUrlExternally for all URLs
        // This properly handles Discord URLs with already-running apps
        Qt.openUrlExternally(location);
    }
}
