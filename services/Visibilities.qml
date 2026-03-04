pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var screensByShellScreen: new Map()
    property var bars: new Map()

    function findMonitorByName(name: string): var {
        return Hypr.monitors.values.find(m => m.name === name);
    }
    
    function load(screen: ShellScreen, visibilities: var): void {
        let monitor = Hypr.monitorFor(screen);
        
        // Workaround: if monitorFor() returns undefined, try matching by name
        if (!monitor) {
            monitor = findMonitorByName(screen.name);
            if (monitor) {
                console.log(`[Visibilities] monitorFor() failed, matched by name: ${screen.name} -> ${monitor.name}`);
            }
        }
        
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
    
    property int monitorCount: Hypr.monitors.values.length
    
    onMonitorCountChanged: {
        // When monitors become available, reload the mappings
        if (screens.size === 0 && screensByShellScreen.size > 0 && monitorCount > 0) {
            console.log(`[Visibilities] Monitors became available (count: ${monitorCount}), reloading mappings`);
            reloadMonitors();
        }
    }
    
    function reloadMonitors(): void {
        console.log(`[Visibilities] reloadMonitors() - attempting to reload monitor mappings`);
        console.log(`[Visibilities] Hyprland.monitors.values.length: ${Hypr.monitors.values.length}`);
        console.log(`[Visibilities] Hyprland monitors: ${Hypr.monitors.values.map(m => m.name).join(", ")}`);
        console.log(`[Visibilities] ShellScreens: ${[...screensByShellScreen.keys()].map(s => s.name).join(", ")}`);
        
        let reloaded = 0;
        for (const [shellScreen, vis] of screensByShellScreen.entries()) {
            let monitor = Hypr.monitorFor(shellScreen);
            
            // Workaround: if monitorFor() returns undefined, try matching by name
            if (!monitor) {
                monitor = findMonitorByName(shellScreen.name);
            }
            
            console.log(`[Visibilities] Trying to map ${shellScreen.name} -> ${monitor?.name ?? "undefined"}`);
            if (monitor && !screens.has(monitor)) {
                screens.set(monitor, vis);
                reloaded++;
                console.log(`[Visibilities] Reloaded monitor mapping: ${shellScreen.name} -> ${monitor.name}`);
            }
        }
        console.log(`[Visibilities] Reload complete - ${reloaded} monitors mapped, total: ${screens.size}`);
    }

    function getForActive(): PersistentProperties {
        console.log(`[Visibilities] getForActive() - focusedMonitor: ${Hypr.focusedMonitor?.name ?? "undefined"}, screens.size: ${screens.size}, screensByShellScreen.size: ${screensByShellScreen.size}`);
        
        // Try to get by focused monitor first
        const visibilities = screens.get(Hypr.focusedMonitor);
        if (visibilities) {
            console.log(`[Visibilities] Found visibilities for focused monitor`);
            return visibilities;
        }
        
        // Fallback 1: if focusedMonitor is undefined, try using focusedWorkspace's monitor
        console.warn(`[Visibilities] No visibilities for focused monitor, trying fallback 1 (workspace monitor)`);
        const workspaceMonitor = Hypr.focusedWorkspace?.monitor;
        if (workspaceMonitor) {
            const workspaceVis = screens.get(workspaceMonitor);
            if (workspaceVis) {
                console.log(`[Visibilities] Fallback 1 succeeded - using workspace monitor: ${workspaceMonitor.name}`);
                return workspaceVis;
            }
        }
        
        // Fallback 2: try first available screen from monitor map
        console.warn(`[Visibilities] Fallback 1 failed, trying fallback 2`);
        const firstScreen = [...screens.values()][0];
        if (firstScreen) {
            console.log(`[Visibilities] Fallback 2 succeeded`);
            return firstScreen;
        }
        
        // Fallback 3: use first ShellScreen (always populated)
        console.warn(`[Visibilities] Fallback 2 failed, trying fallback 3 (first ShellScreen)`);
        const firstShellScreen = [...screensByShellScreen.values()][0];
        console.log(`[Visibilities] Fallback 3: ${firstShellScreen ? "found" : "null"}`);
        return firstShellScreen ?? null;
    }
}
