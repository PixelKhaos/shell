pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    required property var state

    readonly property int currMonth: state.currentDate.getMonth()
    readonly property int currYear: state.currentDate.getFullYear()
    
    property date selectedDate: state.calendarSelectedDate ?? new Date()
    property bool showDayView: state.calendarShowDayView ?? false

    onSelectedDateChanged: state.calendarSelectedDate = selectedDate
    onShowDayViewChanged: state.calendarShowDayView = showDayView

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: monthView.implicitHeight

    CustomMouseArea {
        id: monthView

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: inner.implicitHeight + inner.anchors.margins * 2
        visible: !root.showDayView
        opacity: visible ? 1 : 0

        acceptedButtons: Qt.MiddleButton
        onClicked: root.state.currentDate = new Date()

        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.state.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
            else if (event.angleDelta.y < 0)
                root.state.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
        }

        Behavior on opacity {
            Anim {}
        }

        ColumnLayout {
            id: inner

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.small

            RowLayout {
                id: monthNavigationRow

            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Item {
                implicitWidth: implicitHeight
                implicitHeight: prevMonthText.implicitHeight + Appearance.padding.small * 2

                StateLayer {
                    id: prevMonthStateLayer

                    radius: Appearance.rounding.full

                    function onClicked(): void {
                        root.state.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
                    }
                }

                MaterialIcon {
                    id: prevMonthText

                    anchors.centerIn: parent
                    text: "chevron_left"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 700
                }
            }

            Item {
                Layout.fillWidth: true

                implicitWidth: monthYearDisplay.implicitWidth + Appearance.padding.small * 2
                implicitHeight: monthYearDisplay.implicitHeight + Appearance.padding.small * 2

                StateLayer {
                    anchors.fill: monthYearDisplay
                    anchors.margins: -Appearance.padding.small
                    anchors.leftMargin: -Appearance.padding.normal
                    anchors.rightMargin: -Appearance.padding.normal

                    radius: Appearance.rounding.full
                    disabled: {
                        const now = new Date();
                        return root.currMonth === now.getMonth() && root.currYear === now.getFullYear();
                    }

                    function onClicked(): void {
                        root.state.currentDate = new Date();
                    }
                }

                StyledText {
                    id: monthYearDisplay

                    anchors.centerIn: parent
                    text: grid.title
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                    font.capitalization: Font.Capitalize
                }
            }

            Item {
                implicitWidth: implicitHeight
                implicitHeight: nextMonthText.implicitHeight + Appearance.padding.small * 2

                StateLayer {
                    id: nextMonthStateLayer

                    radius: Appearance.rounding.full

                    function onClicked(): void {
                        root.state.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
                    }
                }

                MaterialIcon {
                    id: nextMonthText

                    anchors.centerIn: parent
                    text: "chevron_right"
                    color: Colours.palette.m3tertiary
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 700
                }
            }
        }

        DayOfWeekRow {
            id: daysRow

            Layout.fillWidth: true
            locale: grid.locale

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.weight: 500
                color: (model.day === 0 || model.day === 6) ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight

            MonthGrid {
                id: grid

                month: root.currMonth
                year: root.currYear

                anchors.fill: parent

                spacing: 3
                locale: Qt.locale()

                delegate: Item {
                    id: dayItem

                    required property var model

                    readonly property bool hasEvents: CalendarEvents.hasEventsOnDate(dayItem.model.date)

                    implicitWidth: implicitHeight
                    implicitHeight: text.implicitHeight + Appearance.padding.small * 2

                    StateLayer {
                        enabled: dayItem.model.month === grid.month

                        function onClicked(): void {
                            root.selectedDate = dayItem.model.date;
                            root.showDayView = true;
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        StyledText {
                            id: text

                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: grid.locale.toString(dayItem.model.day)
                            color: {
                                const dayOfWeek = dayItem.model.date.getUTCDay();
                                if (dayOfWeek === 0 || dayOfWeek === 6)
                                    return Colours.palette.m3secondary;

                                return Colours.palette.m3onSurfaceVariant;
                            }
                            opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                            font.pointSize: Appearance.font.size.normal
                            font.weight: 500
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 4
                            height: 4
                            radius: 2
                            color: Colours.palette.m3primary
                            visible: dayItem.hasEvents && dayItem.model.month === grid.month
                            opacity: text.opacity
                        }
                    }
                }
            }

            StyledRect {
                id: todayIndicator

                readonly property Item todayItem: grid.contentItem.children.find(c => c.model.today) ?? null
                property Item today

                onTodayItemChanged: {
                    if (todayItem)
                        today = todayItem;
                }

                x: today ? today.x + (today.width - implicitWidth) / 2 : 0
                y: today?.y ?? 0

                implicitWidth: today?.implicitWidth ?? 0
                implicitHeight: today?.implicitHeight ?? 0

                clip: true
                radius: Appearance.rounding.full
                color: Colours.palette.m3primary

                opacity: todayItem ? 1 : 0
                scale: todayItem ? 1 : 0.7

                Colouriser {
                    x: -todayIndicator.x
                    y: -todayIndicator.y

                    implicitWidth: grid.width
                    implicitHeight: grid.height

                    source: grid
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onPrimary
                }

                Behavior on opacity {
                    Anim {}
                }

                Behavior on scale {
                    Anim {}
                }

                Behavior on x {
                    Anim {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on y {
                    Anim {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
            }
        }
        }
    }

    Loader {
        id: dayViewLoader

        anchors.fill: parent
        active: root.showDayView
        visible: active
        opacity: visible ? 1 : 0

        sourceComponent: CalendarDayView {
            selectedDate: root.selectedDate

            onBackToMonth: root.showDayView = false
            onAddEvent: {
                root.state.calendarEventModalOpen = true;
                root.state.calendarEventModalEventId = "";
                root.state.calendarEventModalDate = root.selectedDate;
            }
            onEditEvent: eventId => {
                root.state.calendarEventModalOpen = true;
                root.state.calendarEventModalEventId = eventId;
                root.state.calendarEventModalDate = root.selectedDate;
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }
}
