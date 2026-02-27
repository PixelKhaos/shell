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

StyledListView {
    id: root

    required property StyledTextField search
    required property PersistentProperties visibilities

    property string activeCategory: "all"
    property bool showClearConfirmation: false
    property var hoveredItem: null
    property string lastInteraction: "keyboard" // "hover" or "keyboard"

    property bool isCategoryChange: false
    property int deletedItemIndex: -1

    model: ScriptModel {
        id: model

        onValuesChanged: {
            // After deletion, adjust currentIndex if needed
            if (root.deletedItemIndex >= 0) {
                // If we deleted an item before or at current position, move back
                if (root.deletedItemIndex <= root.currentIndex) {
                    root.currentIndex = Math.max(0, root.currentIndex - 1);
                }
                root.deletedItemIndex = -1;
            }
        }
    }

    spacing: Appearance.spacing.small
    orientation: Qt.Vertical
    implicitHeight: {
        if (count === 0)
            return 0;
        const itemsToShow = Math.min(Config.launcher.maxShown, count);
        const calculatedHeight = (Config.launcher.sizes.itemHeight + spacing) * itemsToShow - spacing + (itemsToShow > 0 ? Appearance.spacing.smaller : 0);
        const minHeight = 200;
        return Math.max(minHeight, calculatedHeight);
    }

    onCurrentIndexChanged: {
        root.lastInteraction = "keyboard";
    }

    onContentYChanged: {
        // Clear hover when list scrolls to prevent accidental hover changes
        root.hoveredItem = null;
    }

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Appearance.rounding.normal
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

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
            root.updateModel();
        }
    }

    Connections {
        target: root.search

        function onTextChanged(): void {
            root.updateModel();
        }
    }

    property string previousCategory: "all"
    property var pendingModelUpdate: null

    Connections {
        target: root

        function onActiveCategoryChanged(): void {
            if (previousCategory !== root.activeCategory && root.search.text.startsWith(">clipboard")) {
                if (categoryChangeAnimation.running) {
                    categoryChangeAnimation.stop();
                    root.opacity = 1;
                    root.scale = 1;
                }

                root.pendingModelUpdate = root.filterAndSortItems();
                root.isCategoryChange = true;
                categoryChangeAnimation.start();
            }
            previousCategory = root.activeCategory;
        }
    }

    SequentialAnimation {
        id: categoryChangeAnimation

        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardAccel
            }
            Anim {
                target: root
                property: "scale"
                to: 0.95
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }

        ScriptAction {
            script: {
                // Update model while invisible
                if (root.pendingModelUpdate !== null) {
                    model.values = root.pendingModelUpdate;
                    root.pendingModelUpdate = null;
                    // Only reset to top when switching categories
                    if (root.isCategoryChange) {
                        root.currentIndex = 0;
                        root.positionViewAtBeginning();
                        root.isCategoryChange = false;
                    }
                }
            }
        }

        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 1
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                target: root
                property: "scale"
                to: 1
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        }
    }

    function filterAndSortItems(): var {
        const query = root.search.text.replace(/^>clipboard\s*/i, "").trim();
        let items = Clipboard.history;

        // Filter by category using consistent isImage property
        if (root.activeCategory === "images") {
            items = items.filter(item => item.isImage);
        } else if (root.activeCategory === "misc") {
            items = items.filter(item => !item.isImage);
        }

        // Filter by search query
        if (query) {
            const lowerQuery = query.toLowerCase();
            items = items.filter(item => item.content.toLowerCase().includes(lowerQuery));
        }

        // Sort: pinned items first, preserve original order otherwise
        items.sort((a, b) => {
            if (a.isPinned && !b.isPinned)
                return -1;
            if (!a.isPinned && b.isPinned)
                return 1;
            return a.index - b.index;
        });

        return items;
    }

    function updateModel(): void {
        model.values = root.filterAndSortItems();
    }

    Component.onCompleted: {
        Clipboard.refresh();
        updateModel();
    }

    Behavior on scale {
        Anim {}
    }

    // Confirmation dialog overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.5)
        visible: opacity > 0
        opacity: root.showClearConfirmation ? 1 : 0
        z: 1000

        Behavior on opacity {
            Anim {
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.showClearConfirmation = false
        }

        StyledRect {
            anchors.centerIn: parent
            width: Math.min(400, parent.width - Appearance.padding.large * 2)
            height: confirmContent.implicitHeight + Appearance.padding.large * 2
            color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.large

            opacity: root.showClearConfirmation ? 1 : 0
            scale: root.showClearConfirmation ? 1 : 0.8

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
                }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
                }
            }

            ColumnLayout {
                id: confirmContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (root.activeCategory === "all") {
                            return qsTr("Clear all clipboard items?");
                        } else if (root.activeCategory === "images") {
                            return qsTr("Clear image items?");
                        } else {
                            return qsTr("Clear misc items?");
                        }
                    }
                    font.pointSize: Appearance.font.size.larger
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Non-pinned items in this category will be deleted. Pinned items are preserved.")
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.normal
                    spacing: Appearance.spacing.normal

                    Item {
                        Layout.fillWidth: true
                    }

                    TextButton {
                        text: qsTr("Cancel")
                        type: TextButton.Text
                        onClicked: root.showClearConfirmation = false
                    }

                    TextButton {
                        text: qsTr("Clear All")
                        type: TextButton.Filled
                        onClicked: {
                            root.showClearConfirmation = false;
                            Clipboard.clearAll(root.activeCategory);
                        }
                    }
                }
            }
        }
    }
}
