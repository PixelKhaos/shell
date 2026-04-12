pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.components
import qs.config
import qs.services
import ".."

ColumnLayout {
    id: root

    required property NexusSession session

    spacing: Appearance.spacing.normal

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 44

        StyledRect {
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.6)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.normal
                anchors.rightMargin: Appearance.spacing.normal
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "search"
                    font.pointSize: Appearance.font.size.larger
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                }

                TextField {
                    id: searchField

                    Layout.fillWidth: true

                    placeholderText: "Search settings..."
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurface
                    background: Item {}

                    onTextChanged: {
                        root.session.searchQuery = text;
                    }

                    Component.onCompleted: {
                        searchField.text = root.session.searchQuery;
                        searchField.forceActiveFocus();
                    }
                }

                MaterialIcon {
                    visible: searchField.text.length > 0
                    text: "close"
                    font.pointSize: Appearance.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)

                    StateLayer {
                        function onClicked() {
                            searchField.text = "";
                            root.session.searchQuery = "";
                            searchField.forceActiveFocus();
                        }
                        radius: Appearance.rounding.full
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }
    }

    // Divider
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    }

    // Search results 
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(resultsColumn.height, 300)
        clip: true
        contentHeight: resultsColumn.height
        boundsBehavior: Flickable.StopAtBounds
        visible: root.session.searchQuery.length > 0 && getSearchResults(root.session.searchQuery).length > 0

        Column {
            id: resultsColumn
            width: parent.width
            spacing: 0

            Repeater {
                id: resultsRepeater
                model: getSearchResults(root.session.searchQuery)

                delegate: Item {
                    id: resultDelegate
                    required property var modelData

                    width: parent.width
                    height: 56

                    StateLayer {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Colours.palette.m3onSurface

                        function onClicked() {
                            root.session.setSearchNavigate(resultDelegate.modelData.categoryId, resultDelegate.modelData.tab || "");
                            root.session.searchPopoutOpen = false;
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacing.normal
                        anchors.rightMargin: Appearance.spacing.normal
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: resultDelegate.modelData.icon || "settings"
                            font.pointSize: Appearance.font.size.larger
                            color: Colours.palette.m3onSurface
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - parent.spacing - 32

                            StyledText {
                                text: resultDelegate.modelData.title
                                font.pointSize: Appearance.font.size.normal
                                font.weight: Font.Medium
                                color: Colours.palette.m3onSurface
                            }

                            StyledText {
                                text: resultDelegate.modelData.category + (resultDelegate.modelData.tab ? " · " + resultDelegate.modelData.tab : "")
                                font.pointSize: Appearance.font.size.small - 1
                                color: Qt.alpha(Colours.palette.m3onSurface, 0.5)
                            }
                        }
                    }
                }
            }
        }
    }

    // Empty state
    Item {
        visible: root.session.searchQuery.length === 0
        Layout.fillWidth: true
        Layout.preferredHeight: 100

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            text: "search"
            font.pointSize: Appearance.font.size.larger * 2
            color: Qt.alpha(Colours.palette.m3onSurface, 0.15)
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 50
            text: "Type to search settings"
            font.pointSize: Appearance.font.size.normal
            color: Qt.alpha(Colours.palette.m3onSurface, 0.35)
        }
    }

    // No results
    Item {
        visible: root.session.searchQuery.length > 0 && getSearchResults(root.session.searchQuery).length === 0
        Layout.fillWidth: true
        Layout.preferredHeight: 100

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            text: "sentiment_dissatisfied"
            font.pointSize: Appearance.font.size.larger * 2
            color: Qt.alpha(Colours.palette.m3onSurface, 0.15)
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 50
            text: "No results for \"" + root.session.searchQuery + "\""
            font.pointSize: Appearance.font.size.normal
            color: Qt.alpha(Colours.palette.m3onSurface, 0.35)
        }
    }

    // Clear search when popout closes
    Connections {
        target: root.session
        function onSearchPopoutOpenChanged() {
            if (!root.session.searchPopoutOpen) {
                searchField.text = "";
                root.session.searchQuery = "";
            }
        }
    }

    function getSearchResults(query) {
        // Mock search results - replace with actual search implementation
        const results = [];
        const categories = NexusRegistry.getCategories();

        for (const cat of categories) {
            if (cat.label.toLowerCase().includes(query.toLowerCase())) {
                results.push({
                    categoryId: cat.id,
                    title: cat.label,
                    category: cat.label,
                    icon: cat.icon,
                    tab: ""
                });
            }

            if (cat.children) {
                for (const child of cat.children) {
                    if (child.label.toLowerCase().includes(query.toLowerCase())) {
                        results.push({
                            categoryId: child.id,
                            title: child.label,
                            category: cat.label,
                            icon: child.icon,
                            tab: ""
                        });
                    }
                }
            }
        }

        return results.slice(0, 8);
    }
}
