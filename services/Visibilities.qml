pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var bars: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        const monitor = Hypr.monitorFor(screen);
        console.log(`[Visibilities] load() - screen: ${screen.name}, monitor: ${monitor?.name ?? "undefined"}`);
        if (monitor) {
            screens.set(monitor, visibilities);
            console.log(`[Visibilities] Loaded visibilities for monitor: ${monitor.name}, total screens: ${screens.size}`);
        } else {
            console.warn(`[Visibilities] Could not load visibilities - monitor is undefined for screen: ${screen.name}`);
        }
    }

    function getForActive(): PersistentProperties {
        console.log(`[Visibilities] getForActive() - focusedMonitor: ${Hypr.focusedMonitor?.name ?? "undefined"}, screens.size: ${screens.size}`);
        const visibilities = screens.get(Hypr.focusedMonitor);
        if (visibilities) {
            console.log(`[Visibilities] Found visibilities for focused monitor`);
            return visibilities;
        }
        
        // Fallback: if focused monitor has no visibilities (e.g., disabled monitor),
        // return the first available screen's visibilities
        console.warn(`[Visibilities] No visibilities for focused monitor, using fallback`);
        const firstScreen = [...screens.values()][0];
        console.log(`[Visibilities] Fallback screen: ${firstScreen ? "found" : "null"}`);
        return firstScreen ?? null;
    }
}
