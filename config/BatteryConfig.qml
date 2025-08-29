import Quickshell.Io
import QtQuick

JsonObject {
    property var lowStage: {
        "threshold": 25,
        "title": "Low Battery",
        "message": "Battery is at %1%",
        "urgency": "low",
        "expireTimeout": 6000
    }
    
    property var criticalStage: {
        "threshold": 15,
        "title": "Critical Battery",
        "message": "Battery is at %1%",
        "urgency": "normal",
        "expireTimeout": 10000
    }
    
    property var emergencyStage: {
        "threshold": 5,
        "title": "Battery Emergency",
        "message": "Battery critically low: %1%",
        "urgency": "critical",
        "sleepTimeout": 60,
        "notificationIntervals": [60, 45, 30, 20, 10, 5], // seconds, when to show notifications
        "showTimer": true,
        "expireTimeout": 240000
    }
    
    // General settings
    property bool enableNotifications: true
    property int notificationDelay: 300000 // 5 minutes between repeated notifications
}
