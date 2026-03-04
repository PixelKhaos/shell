pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var screensByShellScreen: new Map()
    property var bars: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        const monitor = Hypr.monitorFor(screen);
        console.log(`[Visibilities] load() - screen: ${screen.name}, monitor: ${monitor?.name ?? "undefined"}`);
        
        // Always store by ShellScreen as a reliable fallback
        screensByShellScreen.set(screen, visibilities);
        console.log(`[Visibilities] Stored visibilities by ShellScreen: ${screen.name}`);
        
        if (monitor) {
            screens.set(monitor, visibilities);
            console.log(`[Visibilities] Loaded visibilities for monitor: ${monitor.name}, total screens: ${screens.size}`);
        } else {
            console.warn(`[Visibilities] Could not load visibilities - monitor is undefined for screen: ${screen.name}`);
        }
    }

    function getForActive(): PersistentProperties {
        console.log(`[Visibilities] getForActive() - focusedMonitor: ${Hypr.focusedMonitor?.name ?? "undefined"}, screens.size: ${screens.size}, screensByShellScreen.size: ${screensByShellScreen.size}`);
        
        // Try to get by focused monitor first
        const visibilities = screens.get(Hypr.focusedMonitor);
        if (visibilities) {
            console.log(`[Visibilities] Found visibilities for focused monitor`);
            return visibilities;
        }
        
        // Fallback 1: try first available screen from monitor map
        console.warn(`[Visibilities] No visibilities for focused monitor, trying fallback 1`);
        const firstScreen = [...screens.values()][0];
        if (firstScreen) {
            console.log(`[Visibilities] Fallback 1 succeeded`);
            return firstScreen;
        }
        
        // Fallback 2: use ShellScreen map (always populated)
        console.warn(`[Visibilities] Fallback 1 failed, trying fallback 2 (ShellScreen map)`);
        const firstShellScreen = [...screensByShellScreen.values()][0];
        console.log(`[Visibilities] Fallback 2: ${firstShellScreen ? "found" : "null"}`);
        return firstShellScreen ?? null;
    }
}
