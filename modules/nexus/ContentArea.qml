pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config
import qs.modules.nexus

Item {
    id: root

    required property NexusSession session

    readonly property var activeConfig: NexusRegistry.getById(session.activeCategory)
    readonly property var tabs: activeConfig ? activeConfig.tabs : []

    property int activeTabIndex: 0

    function updateTabIndicator() {
        const item = tabRepeater.itemAt(activeTabIndex);
        if (item) {
            tabIndicator.targetX = item.x;
            tabIndicator.targetWidth = item.width;
        } else {
            tabIndicator.targetX = 0;
            tabIndicator.targetWidth = 0;
        }
    }

    function onForcedTabChanged() {
        if (session.forcedTab !== "") {
            const tabList = root.tabs;
            for (let i = 0; i < tabList.length; i++) {
                if (tabList[i] === session.forcedTab) {
                    root.activeTabIndex = i;
                    break;
                }
            }
            session.consumeForcedTab();
        }
    }

    onActiveConfigChanged: {
        activeTabIndex = 0;
        tabIndicatorUpdate.restart();
    }

    onActiveTabIndexChanged: {
        tabIndicatorUpdate.restart();
    }

    Timer {
        id: tabIndicatorUpdate

        interval: 0
        onTriggered: root.updateTabIndicator()
    }

    Connections {
        function onForcedTabChanged() {
            root.onForcedTabChanged();
        }

        target: root.session
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: Appearance.padding.large * 2
        anchors.leftMargin: Appearance.padding.large * 2
        anchors.topMargin: Appearance.padding.large
        anchors.bottomMargin: Appearance.padding.large
        spacing: Appearance.spacing.normal

        // Header: title + description
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.padding.smaller

            spacing: Appearance.spacing.small / 2

            StyledText {
                Layout.fillWidth: true
                text: root.activeConfig ? root.activeConfig.title : ""
                font.pointSize: Appearance.font.size.extraLarge
                font.weight: Font.Medium
            }

            StyledText {
                Layout.fillWidth: true
                text: root.activeConfig ? root.activeConfig.description : ""
                font.pointSize: Appearance.font.size.normal
                color: Qt.alpha(Colours.palette.m3onSurface, 0.6)
            }
        }

        Item {
            id: tabBar

            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.smaller
            Layout.preferredHeight: 48
            visible: root.tabs.length > 0

            // Track line
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -8
                height: 1
                color: Qt.alpha(Colours.palette.m3onSurface, 0.1)
            }

            Row {
                id: tabRow

                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 4

                Repeater {
                    id: tabRepeater

                    model: root.tabs

                    delegate: Rectangle {
                        id: tabItem

                        required property string modelData
                        required property int index

                        width: tabLabel.implicitWidth + Appearance.padding.large * 2
                        height: 48
                        radius: Appearance.rounding.small
                        color: "transparent"

                        onXChanged: if (tabItem.index === root.activeTabIndex)
                            tabIndicator.targetX = tabItem.x
                        onWidthChanged: if (tabItem.index === root.activeTabIndex)
                            tabIndicator.targetWidth = tabItem.width

                        StyledText {
                            id: tabLabel

                            anchors.centerIn: parent
                            text: tabItem.modelData
                            font.pointSize: Appearance.font.size.normal
                            font.weight: Font.Medium
                            color: root.activeTabIndex === tabItem.index ? Colours.palette.m3primary : Colours.palette.m3onSurface

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        StateLayer {
                            function onClicked() {
                                root.activeTabIndex = tabItem.index;
                            }

                            radius: Appearance.rounding.small
                            color: root.activeTabIndex === tabItem.index ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        }
                    }
                }
            }

            Rectangle {
                id: tabIndicator

                property real targetX: 0
                property real targetWidth: 0

                anchors.bottom: parent.bottom
                anchors.bottomMargin: -8
                height: 3
                radius: 1.5
                color: Colours.palette.m3primary
                visible: root.tabs.length > 0

                x: targetX
                width: targetWidth

                Behavior on x {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                    }
                }
            }
        }

        // Panel content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Appearance.spacing.normal

            Loader {
                id: panelLoader

                readonly property string targetSource: root.activeConfig ? "panels/" + root.activeConfig.id.charAt(0).toUpperCase() + root.activeConfig.id.slice(1) + "Panel.qml" : ""
                property string resolvedSource: targetSource

                anchors.fill: parent
                asynchronous: true
                source: resolvedSource

                onTargetSourceChanged: resolvedSource = targetSource

                onStatusChanged: {
                    if (status === Loader.Error && resolvedSource !== "panels/PlaceholderPanel.qml") {
                        Qt.callLater(() => {
                            resolvedSource = "panels/PlaceholderPanel.qml";
                        });
                    }
                }

                onLoaded: {
                    if (item && item.hasOwnProperty("activeTabIndex")) {
                        item.activeTabIndex = root.activeTabIndex;
                    }
                }
            }

            Connections {
                function onActiveTabIndexChanged() {
                    if (panelLoader.item && panelLoader.item.hasOwnProperty("activeTabIndex")) {
                        panelLoader.item.activeTabIndex = root.activeTabIndex;
                    }
                }

                target: root
            }
        }
    }
}
