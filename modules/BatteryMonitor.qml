import qs.config
import qs.services
import Caelestia
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root

    readonly property list<var> warnLevels: [...Config.general.battery.warnLevels].sort((a, b) => b.level - a.level)

    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            if (UPower.onBattery) {
                if (Config.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
            } else {
                if (Config.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                for (const level of root.warnLevels)
                    level.warned = false;
            }
        }
    }

    Connections {
        target: UPower.displayDevice

        function onPercentageChanged(): void {
            if (!UPower.onBattery)
                return;

            const p = UPower.displayDevice.percentage * 100;
            for (const level of root.warnLevels) {
                if (p <= level.level && !level.warned) {
                    level.warned = true;
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                }
            }

            if (!hibernateTimer.running && p <= Config.general.battery.criticalLevel) {
                Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
                hibernateTimer.start();
            }
        }
    }

    Connections {
        target: PowerProfiles

        function onProfileChanged(): void {
            if (PowerProfiles.profile === PowerProfile.PowerSaver) {
                // Apply Hyprland power saving options
                 Hypr.extras.applyOptions({
                    "animations:enabled": 0,
                    "decoration:blur:enabled": 0,
                    "decoration:rounding": 0,
                    "decoration:shadow:enabled": 0
                });

                // Set all monitors with refresh rate > 60 to 60Hz
                const monitors = Hypr.monitors.values || Object.values(Hypr.monitors);
                for (const monitor of monitors) {
                    const data = monitor.lastIpcObject;
                    if (data && data.refreshRate > 60) {
                        Hypr.extras.message(`keyword monitor ${data.name},${data.width}x${data.height}@60,${data.x}x${data.y},${data.scale}`);
                    }
                }

                if (Config.utilities.toasts.lowPowerModeChanged)
                    Toaster.toast(qsTr("Low power mode enabled"), qsTr("Disabled animations, blur, rounding, shadows and set FPS to 60"), "battery_saver");
            } else {
                // Restore default settings by reloading Hyprland config
                Hypr.extras.message("reload");
                
                if (Config.utilities.toasts.lowPowerModeChanged)
                    Toaster.toast(qsTr("Low power mode disabled"), qsTr("Settings and performance restored"), "battery_saver");
            }
        }
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
    }
}
