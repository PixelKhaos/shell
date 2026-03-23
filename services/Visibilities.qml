pragma Singleton

import Quickshell
import qs.components
import qs.services

Singleton {
    property var screens: new Map()
    property var bars: new Map()
    property var panels: new Map()

    function load(screen: ShellScreen, visibilities: DrawerVisibilities): void {
        screens.set(Hypr.monitorFor(screen), visibilities);
    }

    function loadPanels(screen: ShellScreen, panelRefs: var): void {
        panels.set(Hypr.monitorFor(screen), panelRefs);
    }

    function getForActive(): PersistentProperties {
        return screens.get(Hypr.focusedMonitor);
    }
}
