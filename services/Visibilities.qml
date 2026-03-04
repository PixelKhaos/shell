pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var bars: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        const monitor = Hypr.monitorFor(screen);
        if (monitor)
            screens.set(monitor, visibilities);
    }

    function getForActive(): PersistentProperties {
        const visibilities = screens.get(Hypr.focusedMonitor);
        if (visibilities)
            return visibilities;
        
        // Fallback: if focused monitor has no visibilities (e.g., disabled monitor),
        // return the first available screen's visibilities
        const firstScreen = [...screens.values()][0];
        return firstScreen ?? null;
    }
}
