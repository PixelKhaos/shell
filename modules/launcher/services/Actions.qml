pragma Singleton

import ".."
import qs.services
import qs.config
import qs.utils
import Caelestia
import Quickshell
import QtQuick

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(Config.launcher.actionPrefix.length);
    }

    function toggleFavorite(appId: string, appName: string): void {
        const favorites = Config.launcher.favoriteApps;
        const index = favorites.indexOf(appId);
        
        if (index >= 0) {
            // Remove from favorites
            Config.launcher.favoriteApps = favorites.filter(id => id !== appId);
            Toaster.toast(qsTr("Removed from favorites"), appName, "heart_broken");
        } else {
            // Add to favorites
            Config.launcher.favoriteApps = [...favorites, appId];
            Toaster.toast(qsTr("Added to favorites"), appName, "favorite");
        }
        
        Config.save();
    }

    list: variants.instances
    useFuzzy: Config.launcher.useFuzzy.actions

    Variants {
        id: variants

        model: Config.launcher.actions.filter(a => (a.enabled ?? true) && (Config.launcher.enableDangerousActions || !(a.dangerous ?? false)))

        Action {}
    }

    component Action: QtObject {
        required property var modelData
        readonly property string name: modelData.name ?? qsTr("Unnamed")
        readonly property string desc: modelData.description ?? qsTr("No description")
        readonly property string icon: modelData.icon ?? "help_outline"
        readonly property list<string> command: modelData.command ?? []
        readonly property bool enabled: modelData.enabled ?? true
        readonly property bool dangerous: modelData.dangerous ?? false

        function onClicked(list: AppList): void {
            if (command.length === 0)
                return;

            if (command[0] === "autocomplete" && command.length > 1) {
                list.search.text = `${Config.launcher.actionPrefix}${command[1]} `;
            } else if (command[0] === "setMode" && command.length > 1) {
                list.visibilities.launcher = false;
                Colours.setMode(command[1]);
            } else {
                list.visibilities.launcher = false;
                Quickshell.execDetached(command);
            }
        }
    }
}
