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
import QtQuick.Layouts

Item {
    id: root

    required property StyledTextField search
    required property PersistentProperties visibilities

    property string activeCategory: "all"

    readonly property int columns: 5
    readonly property int cellSize: Math.floor((Config.launcher.sizes.itemWidth - Appearance.padding.normal * 2) / columns)
    readonly property alias currentItem: grid.currentItem
    readonly property alias count: grid.count
    property int currentIndex: 0

    implicitWidth: Config.launcher.sizes.itemWidth
    implicitHeight: 100

    Binding {
        target: root
        property: "implicitHeight"
        value: categoryBar.height + grid.height + Appearance.padding.large
        when: categoryBar.height > 0 && grid.height > 0
    }

    function incrementCurrentIndex(): void {
        const newIndex = currentIndex + columns;
        if (newIndex < grid.count) {
            currentIndex = newIndex;
        } else if (currentIndex < grid.count - 1) {
            currentIndex = grid.count - 1;
        }
    }

    function decrementCurrentIndex(): void {
        const newIndex = currentIndex - columns;
        if (newIndex >= 0) {
            currentIndex = newIndex;
        } else if (currentIndex > 0) {
            currentIndex = 0;
        }
    }

    function moveLeft(): void {
        if (currentIndex > 0) {
            currentIndex = currentIndex - 1;
        }
    }

    function moveRight(): void {
        if (currentIndex < grid.count - 1) {
            currentIndex = currentIndex + 1;
        }
    }

    onCurrentIndexChanged: {
        if (grid.currentIndex !== currentIndex) {
            grid.currentIndex = currentIndex;
        }
    }

    RowLayout {
        id: categoryBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Appearance.spacing.small

        Repeater {
            model: Emojis.categories

            IconButton {
                required property var modelData
                required property int index

                icon: modelData.icon
                type: root.activeCategory === modelData.id ? IconButton.Filled : IconButton.Tonal
                onClicked: {
                    root.activeCategory = modelData.id;
                    updateGrid();
                }
            }
        }
    }

    GridView {
        id: grid

        anchors.top: categoryBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        anchors.topMargin: Appearance.padding.large

        height: Math.min(Math.max(contentHeight, root.cellSize * 3), 400)
        clip: true

        cellWidth: root.cellSize
        cellHeight: root.cellSize

        verticalLayoutDirection: GridView.TopToBottom

        highlight: Rectangle {
            color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
            radius: Appearance.rounding.normal
        }
        highlightFollowsCurrentItem: true

        model: ScriptModel {
            id: model

            onValuesChanged: {
                grid.currentIndex = 0;
                root.currentIndex = 0;
            }
        }

        delegate: emojiItem

        Component {
            id: emojiItem

            EmojiItem {
                width: grid.cellWidth - Appearance.spacing.small
                height: grid.cellHeight - Appearance.spacing.small
                visibilities: root.visibilities
            }
        }

        Keys.onLeftPressed: {
            if (currentIndex % root.columns === 0) {
                event.accepted = false;
            } else {
                root.moveLeft();
            }
        }

        Keys.onRightPressed: {
            if (currentIndex % root.columns === root.columns - 1) {
                event.accepted = false;
            } else {
                root.moveRight();
            }
        }

        Keys.onUpPressed: {
            if (currentIndex < root.columns) {
                event.accepted = false;
            } else {
                currentIndex -= root.columns;
            }
        }

        Keys.onDownPressed: {
            if (currentIndex >= count - root.columns) {
                event.accepted = false;
            } else {
                currentIndex += root.columns;
            }
        }
    }

    Connections {
        function onEmojisLoaded(): void {
            updateGrid();
        }

        target: Emojis
    }

    Connections {
        function onTextChanged(): void {
            updateGrid();
        }

        target: root.search
    }

    function updateGrid(): void {
        const pattern = new RegExp("^" + Config.launcher.actionPrefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + "emoji\\s*", "i");
        const query = root.search.text.replace(pattern, "").trim();

        let items;

        if (query) {
            // Search mode - ignore category
            items = Emojis.search(query);
        } else {
            // Category mode
            items = Emojis.filterByCategory(root.activeCategory);
        }

        model.values = items;
    }

    Component.onCompleted: {
        updateGrid();
    }
}
