pragma Singleton
pragma ComponentBehavior: Bound

import qs.config
import qs.services
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    // Track notification states
    property var lastNotificationTimes: ({})
    property var activeNotifications: ({})
    property bool emergencyNotificationActive: false
    property int currentEmergencyTimer: 0
    
    // Reference to the Notifs service
    property var notifService: Notifs
    
    // We'll use Component.onCompleted for initialization instead of Connections
    // since UPower doesn't have the signals we need
    
    // Connect directly to the display device when it's available
    Component.onCompleted: {
        console.log("[BatteryNotifier] Component initialized");
        
        // Initial battery check
        if (UPower.displayDevice) {
            // Connect to display device percentage changes
            UPower.displayDevice.percentageChanged.connect(function() {
                console.log("[BatteryNotifier] Battery percentage changed");
                checkBatteryStatus();
            });
            
            // Log battery status information
            const percentage = Math.round(UPower.displayDevice.percentage * 100);
            console.log(`[BatteryNotifier] Initial battery level: ${percentage}%`);
            console.log(`[BatteryNotifier] Is on battery: ${UPower.onBattery}`);
            console.log(`[BatteryNotifier] Low threshold: ${Config.battery.lowStage.threshold}%`);
            console.log(`[BatteryNotifier] Critical threshold: ${Config.battery.criticalStage.threshold}%`);
            console.log(`[BatteryNotifier] Emergency threshold: ${Config.battery.emergencyStage.threshold}%`);
            
            // Initial check
            checkBatteryStatus();
        } else {
            console.log("[BatteryNotifier] No display device available");
        }
    }
    
    // Connect to UPower onBattery changes
    Connections {
        target: UPower
        
        function onOnBatteryChanged() {
            console.log("[BatteryNotifier] Charger state changed: onBattery = " + UPower.onBattery);
            
            // Clear battery notifications when charger is connected
            if (!UPower.onBattery) {
                clearBatteryNotifications();
                resetNotificationState();
                emergencyTimer.running = false;
                console.log("[BatteryNotifier] Charger plugged in, notifications cleared");
            } else {
                // Reset state when charger is disconnected
                resetNotificationState();
                
                // Wait a moment before checking battery status
                notificationDelayTimer.callback = function() {
                    console.log("[BatteryNotifier] Checking battery status after unplug");
                    checkBatteryStatus();
                };
                notificationDelayTimer.interval = 1000;
                notificationDelayTimer.restart();
            }
        }
    }
    
    // Reset all notification state
    function resetNotificationState() {
        lastNotificationTimes = {};
        activeNotifications = {};
        emergencyNotificationActive = false;
        currentEmergencyTimer = 0;
    }
    
    // Timer to periodically check battery status
    Timer {
        id: batteryCheckTimer
        interval: 3000 // Check every 3 seconds for testing
        running: UPower.displayDevice && UPower.displayDevice.isLaptopBattery && Config.battery.enableNotifications
        repeat: true
        onTriggered: {
            console.log("[BatteryNotifier] Timer check triggered");
            checkBatteryStatus();
        }
    }
    
    // Timer for emergency countdown
    Timer {
        id: emergencyTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (currentEmergencyTimer > 0) {
                currentEmergencyTimer--;
                updateEmergencyNotification();
            } else {
                emergencyTimer.running = false;
                if (emergencyNotificationActive) {
                    sleepSystem();
                }
            }
        }
    }
    
    // Timer for delaying notification sending
    Timer {
        id: notificationDelayTimer
        repeat: false
        running: false
        property var callback: null
        
        onTriggered: {
            if (callback) {
                callback();
                callback = null;
            }
        }
    }
    
    // Check battery status and show notifications if needed
    function checkBatteryStatus() {
        if (!UPower.displayDevice || !UPower.displayDevice.isLaptopBattery) {
            console.log("[BatteryNotifier] No laptop battery detected");
            return;
        }
        
        const percentage = Math.round(UPower.displayDevice.percentage * 100);
        console.log(`[BatteryNotifier] Checking battery status: ${percentage}%`);
        console.log(`[BatteryNotifier] Active notifications: ${JSON.stringify(Object.keys(activeNotifications))}`);
        
        // Don't show notifications if not on battery
        if (!UPower.onBattery) {
            console.log("[BatteryNotifier] Not on battery power, skipping notifications");
            return;
        }
        
        // Check emergency level first (most critical)
        if (percentage <= Config.battery.emergencyStage.threshold) {
            console.log(`[BatteryNotifier] Battery at emergency level: ${percentage}%`);
            
            const now = Date.now();
            const lastTime = lastNotificationTimes.emergency || 0;
            const timeSinceLast = now - lastTime;
            
            // Show notification if not already active or if enough time has passed
            if (!emergencyNotificationActive && (timeSinceLast > Config.battery.notificationDelay)) {
                showEmergencyNotification(percentage);
            }
        }
        // Check critical level
        else if (percentage <= Config.battery.criticalStage.threshold) {
            const now = Date.now();
            const lastTime = lastNotificationTimes.critical || 0;
            const timeSinceLast = now - lastTime;
            
            // Show notification if not already active or if enough time has passed
            if (!activeNotifications.critical && (timeSinceLast > Config.battery.notificationDelay)) {
                showCriticalNotification(percentage);
            }
        }
        // Check low level
        else if (percentage <= Config.battery.lowStage.threshold) {
            const now = Date.now();
            const lastTime = lastNotificationTimes.low || 0;
            const timeSinceLast = now - lastTime;
            
            // Show notification if not already active or if enough time has passed
            if (!activeNotifications.low && (timeSinceLast > Config.battery.notificationDelay)) {
                showLowNotification(percentage);
            }
        }
    }
    
    // Show low battery notification
    function showLowNotification(percentage) {
        const config = Config.battery.lowStage;
        
        // Clear any existing battery notifications first
        clearBatteryNotifications();
        
        // Send notification
        sendNotification({
            title: config.title,
            message: config.message.replace("%1", percentage),
            urgency: config.urgency,
            expireTimeout: config.expireTimeout
        });
        
        // Update state
        lastNotificationTimes.low = Date.now();
        activeNotifications.low = true;
        
        // Auto-expire notification after timeout
        if (config.expireTimeout > 0) {
            const timer = new Timer();
            timer.interval = config.expireTimeout + 500;
            timer.repeat = false;
            timer.triggered.connect(() => {
                activeNotifications.low = false;
                timer.destroy();
            });
            timer.start();
        }
    }
    
    // Show critical battery notification
    function showCriticalNotification(percentage) {
        const config = Config.battery.criticalStage;
        
        // Clear any existing battery notifications first
        clearBatteryNotifications();
        
        // Send notification
        sendNotification({
            title: config.title,
            message: config.message.replace("%1", percentage),
            urgency: config.urgency,
            expireTimeout: config.expireTimeout
        });
        
        // Update state
        lastNotificationTimes.critical = Date.now();
        activeNotifications.critical = true;
        
        // Auto-expire notification after timeout
        if (config.expireTimeout > 0) {
            const timer = new Timer();
            timer.interval = config.expireTimeout + 500;
            timer.repeat = false;
            timer.triggered.connect(() => {
                activeNotifications.critical = false;
                timer.destroy();
            });
            timer.start();
        }
    }
    
    // Show emergency battery notification with countdown
    function showEmergencyNotification(percentage) {
        console.log("[BatteryNotifier] showEmergencyNotification called with percentage: " + percentage);
        const config = Config.battery.emergencyStage;
        
        clearBatteryNotifications();
        
        emergencyNotificationActive = true;
        currentEmergencyTimer = config.sleepTimeout;
        
        console.log(`[BatteryNotifier] Emergency timer set to: ${currentEmergencyTimer}`);
        
        let initialMessage = config.message.replace("%1", percentage);
        if (config.showTimer) {
            initialMessage += `\nSystem will sleep in ${currentEmergencyTimer} seconds.`;
        }
        
        sendNotification({
            title: config.title,
            message: initialMessage,
            urgency: config.urgency,
            expireTimeout: config.expireTimeout
        });
        
        lastNotificationTimes.emergency = Date.now();
        activeNotifications.emergency = true;
        console.log("[BatteryNotifier] Emergency notification state set to active");
        
        emergencyTimer.restart();
    }
    
    function updateEmergencyNotification() {
        console.log(`[BatteryNotifier] Countdown: ${currentEmergencyTimer} seconds remaining`);
        const config = Config.battery.emergencyStage;
        
        if (config.notificationIntervals.includes(currentEmergencyTimer)) {            
            clearBatteryNotifications();
            
            let message = `Battery low - System will sleep in ${currentEmergencyTimer} seconds!`;
            
            sendNotification({
                title: "Battery Emergency",
                message: message,
                urgency: "critical",
                expireTimeout: 0
            });
            
            console.log(`[BatteryNotifier] Sent interval notification at ${currentEmergencyTimer} seconds`);
        } else {
            console.log(`[BatteryNotifier] No interval match for ${currentEmergencyTimer} seconds. Available intervals: ${JSON.stringify(config.notificationIntervals)}`);
        }
    }
    
    function clearBatteryNotifications() {        
        activeNotifications = ({});
        
        // Use direct manipulation of the notifications list
        if (notifService && notifService.list) {
            let clearedCount = 0;
            for (let i = 0; i < notifService.list.length; i++) {
                let notif = notifService.list[i];
                if (notif && notif.notification && notif.notification.appName === "Battery") {
                    console.log(`[BatteryNotifier] Clearing notification: ${notif.summary}`);
                    notif.popup = false;
                    clearedCount++;
                }
            }
            //console.log(`[BatteryNotifier] Cleared ${clearedCount} notifications using direct manipulation`);
        } else {
            console.log("[BatteryNotifier] Notifs service not available or has no list property");
        }
    }
    
    function sendNotification(options) {
        try {
            console.log(`[BatteryNotifier] Sending notification: ${options.title} - ${options.message}`);
            
            activeNotifications[options.urgency || "normal"] = true;
            
            let args = [
                "notify-send",
                "-a", "Battery",
                "-u", options.urgency || "normal"
            ];
            
            // Add timeout if specified - use much longer timeout for critical notifications
            if (options.urgency === "critical") {
                // For critical notifications, use a very long timeout (2 minutes)
                args.push("-t");
                args.push("120000");
            } else if (options.expireTimeout > 0) {
                // For normal notifications, use the specified timeout but make it longer
                args.push("-t");
                args.push((options.expireTimeout * 2).toString());
            }
            
            args.push(options.title);
            args.push(options.message);
            
            //console.log(`[BatteryNotifier] Running: ${args.join(" ")}`);
            
            // Execute the command detached
            Quickshell.execDetached(args);
            
            console.log(`[BatteryNotifier] Command executed successfully`);
        } catch (e) {
            console.log(`[BatteryNotifier] Error sending notification: ${e}`);
        }
    }
    
    // Sleep the system - commented out for testing
    function sleepSystem() {
        console.log("[BatteryNotifier] Would initiate system sleep (commented out for testing)");
        // Uncomment to actually sleep the system
        // let sleepProcess = new Process();
        // sleepProcess.command = ["systemctl", "suspend"];
        // sleepProcess.running = true;
    }
}
