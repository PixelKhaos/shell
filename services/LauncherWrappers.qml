pragma Singleton

import Quickshell

Singleton {
    property var wrappers: new Map()

    function register(screen: var, wrapper: var): void {
        wrappers.set(Hypr.monitorFor(screen), wrapper);
    }

    function getForActive(): var {
        return wrappers.get(Hypr.focusedMonitor);
    }
}
