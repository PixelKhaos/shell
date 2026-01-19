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

    property string activeCategory: "people"

    readonly property int cellSize: 80
    readonly property alias currentItem: grid.currentItem
    readonly property alias count: grid.count
    readonly property int columns: Math.max(1, Math.floor(grid.width / cellSize))
    property int currentIndex: 0

    implicitWidth: Config.launcher.sizes.width
    implicitHeight: 100
    
    Binding {
        target: root
        property: "implicitHeight"
        value: categoryBar.height + grid.height + Appearance.spacing.normal
        when: categoryBar.height > 0 && grid.height > 0
    }

    onCurrentIndexChanged: {
        grid.currentIndex = currentIndex;
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
        anchors.topMargin: Appearance.spacing.normal
        
        height: Math.min(contentHeight, 400)
        clip: true

        cellWidth: root.cellSize
        cellHeight: root.cellSize
        
        highlight: Rectangle {
            color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
            radius: Appearance.rounding.normal
        }
        highlightFollowsCurrentItem: true

        model: ScriptModel {
            id: model

            onValuesChanged: {
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
            if (currentIndex % 5 === 0) {
                event.accepted = false;
            } else {
                decrementCurrentIndex();
            }
        }

        Keys.onRightPressed: {
            if (currentIndex % 5 === 4) {
                event.accepted = false;
            } else {
                incrementCurrentIndex();
            }
        }

        Keys.onUpPressed: {
            if (currentIndex < 5) {
                event.accepted = false;
            } else {
                currentIndex -= 5;
            }
        }

        Keys.onDownPressed: {
            if (currentIndex >= count - 5) {
                event.accepted = false;
            } else {
                currentIndex += 5;
            }
        }
    }

    Connections {
        target: Emojis

        function onEmojisLoaded(): void {
            updateGrid();
        }
    }

    Connections {
        target: root.search

        function onTextChanged(): void {
            updateGrid();
        }
    }

    function updateGrid(): void {
        const query = root.search.text.replace(/^>emoji\s*/i, "").trim();
        
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
