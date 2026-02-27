pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

TabNavbar {
    id: root

    required property var categories
    required property string activeCategory

    signal categoryChanged(string categoryId)

    tabs: root.categories
    activeTab: root.activeCategory
    showScrollButtons: true

    onTabChanged: tabId => {
        root.categoryChanged(tabId);
    }
}
