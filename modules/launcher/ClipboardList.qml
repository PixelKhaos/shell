pragma ComponentBehavior: Bound

import "items"
import "services"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick

StyledListView {
    id: root

    required property StyledTextField search
    required property PersistentProperties visibilities

    model: ScriptModel {
        id: model

        onValuesChanged: {
            root.currentIndex = 0;
        }
    }

    spacing: Appearance.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Config.launcher.sizes.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange
    
    highlight: Rectangle {
        color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
        radius: Appearance.rounding.normal
    }
    highlightFollowsCurrentItem: true

    delegate: clipboardItem

    Component {
        id: clipboardItem

        ClipboardItem {
            visibilities: root.visibilities
        }
    }

    Connections {
        target: Clipboard

        function onHistoryChanged(): void {
            updateModel();
        }
    }

    Connections {
        target: root.search

        function onTextChanged(): void {
            updateModel();
        }
    }

    function updateModel(): void {
        const query = root.search.text.replace(/^>clipboard\s*/i, "").trim();
        
        let items = Clipboard.history;
        
        // Filter by search query
        if (query) {
            const lowerQuery = query.toLowerCase();
            items = items.filter(item => {
                return item.content.toLowerCase().includes(lowerQuery);
            });
        }

        // pinned items first
        items.sort((a, b) => {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return a.index - b.index;
        });

        model.values = items;
    }

    Component.onCompleted: {
        Clipboard.refresh();
        updateModel();
    }
}
