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
    readonly property string dataPath: Config.utilities.calendar.dataPath.replace(/^~/, Quickshell.env("HOME"))

    function generateId(): string {
        return Date.now().toString(36) + Math.random().toString(36).substring(2);
    }

    function createEvent(title, start, end, description, location, color, reminders, recurrence): string {
        const event = {
            id: generateId(),
            title: title || "Untitled Event",
            description: description || "",
            start: start,
            end: end,
            location: location || "",
            color: color || "#2196F3",
            reminders: reminders || [],
            recurrence: recurrence || null,
            created: new Date().toISOString(),
            modified: new Date().toISOString()
        };

        const newEvents = root.events.slice();
        
        // If recurring, generate instances for the next 90 days
        if (recurrence) {
            const instances = generateRecurringInstances(event, 90);
            newEvents.push(...instances);
        } else {
            newEvents.push(event);
        }
        
        root.events = newEvents;
        saveEvents();

        return event.id;
    }
    
    function generateRecurringInstances(baseEvent, daysAhead): list<var> {
        const instances = [];
        const startDate = new Date(baseEvent.start);
        const endDate = new Date(baseEvent.end);
        const duration = endDate - startDate;
        const maxDate = new Date(startDate.getTime() + (daysAhead * 86400000));
        
        let currentDate = new Date(startDate);
        let instanceCount = 0;
        const maxInstances = 365; // Safety limit
        
        while (currentDate <= maxDate && instanceCount < maxInstances) {
            const instance = Object.assign({}, baseEvent);
            instance.id = generateId();
            instance.start = currentDate.toISOString();
            instance.end = new Date(currentDate.getTime() + duration).toISOString();
            instance.isRecurringInstance = true;
            instance.parentRecurrence = baseEvent.recurrence;
            
            instances.push(instance);
            instanceCount++;
            
            // Calculate next occurrence
            const recurrence = baseEvent.recurrence;
            if (recurrence.type === "daily") {
                currentDate.setDate(currentDate.getDate() + 1);
            } else if (recurrence.type === "weekly") {
                currentDate.setDate(currentDate.getDate() + 7);
            } else if (recurrence.type === "biweekly") {
                currentDate.setDate(currentDate.getDate() + 14);
            } else if (recurrence.type === "monthly") {
                currentDate.setMonth(currentDate.getMonth() + 1);
            } else if (recurrence.type === "custom") {
                const interval = recurrence.interval || 1;
                if (recurrence.unit === "days") {
                    currentDate.setDate(currentDate.getDate() + interval);
                } else if (recurrence.unit === "weeks") {
                    currentDate.setDate(currentDate.getDate() + (interval * 7));
                } else if (recurrence.unit === "months") {
                    currentDate.setMonth(currentDate.getMonth() + interval);
                }
            }
        }
        
        return instances;
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
    
    function deleteRecurringSeries(recurrence): void {
        if (!recurrence) return;
        
        // Delete all events with matching parent recurrence
        const newEvents = root.events.filter(e => {
            if (!e.parentRecurrence) return true;
            return JSON.stringify(e.parentRecurrence) !== JSON.stringify(recurrence);
        });
        
        root.events = newEvents;
        saveEvents();
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
                    sendEventNotification(event, reminder.offset);

                    // Mark as triggered (in memory only, not saved)
                    reminder.triggered = true;
                }
            });
        });
    }

    function sendEventNotification(event, offsetSeconds): void {
        const eventStart = new Date(event.start);
        const timeStr = eventStart.toLocaleTimeString(Qt.locale(), "hh:mm");
        
        let title = event.title;
        let body = "";
        
        if (offsetSeconds > 0) {
            const minutes = Math.floor(offsetSeconds / 60);
            if (minutes === 0) {
                body = qsTr("Starting now");
            } else if (minutes < 60) {
                body = qsTr("Starting in %1 minutes").arg(minutes);
            } else {
                const hours = Math.floor(minutes / 60);
                body = qsTr("Starting in %1 hours").arg(hours);
            }
        } else {
            body = qsTr("Starting at %1").arg(timeStr);
        }
        
        // Add location if present
        if (event.location) {
            const isUrl = event.location.startsWith('http://') || event.location.startsWith('https://');
            
            if (isUrl) {
                // Show Discord icon for Discord URLs, link icon for others
                if (event.location.includes('discord.com')) {
                    body += `\n💬 ${event.location}`;
                } else {
                    body += `\n🔗 ${event.location}`;
                }
            } else {
                body += `\n📍 ${event.location}`;
            }
        }
        
        if (event.description && event.description.length < 100) {
            body += `\n${event.description}`;
        }
        
        // Send notification
        Quickshell.execDetached([
            "notify-send",
            "-u", "normal",
            "-i", "x-office-calendar",
            "-a", "Calendar",
            title,
            body
        ]);
    }

    // Timer to regenerate recurring events daily
    Timer {
        running: enabled
        repeat: true
        interval: 86400000 // 24 hours
        triggeredOnStart: false
        onTriggered: regenerateRecurringEvents()
    }
    
    function regenerateRecurringEvents(): void {
        // Find all unique recurring event templates (first instance of each series)
        const recurringTemplates = new Map();
        
        root.events.forEach(event => {
            if (event.recurrence && !event.isRecurringInstance) {
                recurringTemplates.set(JSON.stringify(event.recurrence), event);
            }
        });
        
        if (recurringTemplates.size === 0) return;
        
        // Remove old recurring instances
        let newEvents = root.events.filter(e => !e.isRecurringInstance);
        
        // Regenerate instances for each template
        recurringTemplates.forEach(template => {
            const instances = generateRecurringInstances(template, 90);
            newEvents.push(...instances);
        });
        
        root.events = newEvents;
        saveEvents();
    }

    Component.onCompleted: enabled && loadEvents()
}
