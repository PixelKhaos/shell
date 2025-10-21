pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import Caelestia

Singleton {
    id: root

    property list<var> events: []
    property bool loaded: false

    readonly property bool enabled: Config.utilities.calendar.enabled
    readonly property string dataPath: Config.utilities.calendar.dataPath

    function generateId(): string {
        return Date.now().toString(36) + Math.random().toString(36).substring(2);
    }

    function createEvent(title, start, end, description, location, color, reminders): string {
        const event = {
            id: generateId(),
            title: title || "Untitled Event",
            description: description || "",
            start: start,
            end: end,
            location: location || "",
            color: color || "#2196F3",
            reminders: reminders || [],
            created: new Date().toISOString(),
            modified: new Date().toISOString()
        };

        const newEvents = root.events.slice();
        newEvents.push(event);
        root.events = newEvents;
        saveEvents();

        return event.id;
    }

    function updateEvent(id, updates): bool {
        const index = root.events.findIndex(e => e.id === id);
        if (index === -1)
            return false;

        const newEvents = root.events.slice();
        const updated = Object.assign({}, newEvents[index], updates);
        updated.modified = new Date().toISOString();
        newEvents[index] = updated;
        root.events = newEvents;
        saveEvents();

        return true;
    }

    function deleteEvent(id): bool {
        const index = root.events.findIndex(e => e.id === id);
        if (index === -1)
            return false;

        const newEvents = root.events.slice();
        newEvents.splice(index, 1);
        root.events = newEvents;
        saveEvents();

        return true;
    }

    function getEvent(id): var {
        return root.events.find(e => e.id === id) ?? null;
    }

    function getEventsForDate(date): list<var> {
        const targetDate = new Date(date);
        targetDate.setHours(0, 0, 0, 0);
        const nextDay = new Date(targetDate);
        nextDay.setDate(nextDay.getDate() + 1);

        return root.events.filter(e => {
            const eventStart = new Date(e.start);
            eventStart.setHours(0, 0, 0, 0);
            return eventStart.getTime() === targetDate.getTime();
        }).sort((a, b) => new Date(a.start) - new Date(b.start));
    }

    function hasEventsOnDate(date): bool {
        const targetDate = new Date(date);
        targetDate.setHours(0, 0, 0, 0);

        return root.events.some(e => {
            const eventStart = new Date(e.start);
            eventStart.setHours(0, 0, 0, 0);
            return eventStart.getTime() === targetDate.getTime();
        });
    }

    function getUpcomingEvents(days): list<var> {
        const now = new Date();
        const future = new Date();
        future.setDate(future.getDate() + days);

        return root.events.filter(e => {
            const eventStart = new Date(e.start);
            return eventStart >= now && eventStart <= future;
        }).sort((a, b) => new Date(a.start) - new Date(b.start));
    }

    function loadEvents(): void {
        if (!enabled)
            return;

        loadProc.running = true;
    }

    function saveEvents(): void {
        if (!enabled)
            return;

        const data = {
            version: 1,
            events: root.events
        };

        saveProc.exec([
            "sh", "-c",
            `mkdir -p "$(dirname "${dataPath}")" && echo '${JSON.stringify(data)}' > "${dataPath}"`
        ]);
    }

    Process {
        id: loadProc

        command: ["cat", dataPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data.events && Array.isArray(data.events)) {
                        root.events = data.events;
                    }
                } catch (e) {
                    console.warn("Failed to parse calendar data:", e);
                    root.events = [];
                }
                root.loaded = true;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    console.log("Calendar data file not found, starting fresh");
                    root.events = [];
                }
                root.loaded = true;
            }
        }
    }

    Process {
        id: saveProc
    }

    // Check for upcoming reminders every minute
    Timer {
        id: reminderTimer

        interval: 60000
        running: enabled && loaded
        repeat: true
        onTriggered: root.checkReminders()
    }

    function checkReminders(): void {
        if (!Config.utilities.calendar.showReminderToasts)
            return;

        const now = new Date();
        const nowTime = now.getTime();

        root.events.forEach(event => {
            const eventStart = new Date(event.start);
            const eventTime = eventStart.getTime();

            if (eventTime <= nowTime)
                return;

            event.reminders?.forEach(reminder => {
                const reminderTime = eventTime - (reminder.offset * 1000);
                const timeDiff = Math.abs(reminderTime - nowTime);

                // Trigger if within 30 seconds of reminder time
                if (timeDiff < 30000 && !reminder.triggered) {
                    const timeStr = eventStart.toLocaleTimeString(Qt.locale(), "hh:mm");
                    const title = qsTr("Reminder: %1").arg(event.title);
                    const body = event.location
                        ? qsTr("%1 at %2").arg(timeStr).arg(event.location)
                        : timeStr;

                    Toaster.toast(title, body, "event");

                    // Mark as triggered (in memory only, not saved)
                    reminder.triggered = true;
                }
            });
        });
    }

    Component.onCompleted: enabled && loadEvents()
}
