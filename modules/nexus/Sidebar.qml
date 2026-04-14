pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config
import qs.modules.nexus
import "./components"

Item {
    id: root

    required property NexusSession session

    property string flyoutCategory: ""
    property real flyoutTop: 0
    property string _pendingCategory: ""

    function openFlyout(categoryId, itemGlobalY) {
        flyoutCloseTimer.stop();

        const cat = NexusRegistry.getById(categoryId);
        const childCount = cat && cat.children ? cat.children.length : 0;
        const flyoutHeight = childCount * 68 + 36;
        let top = itemGlobalY - flyoutHeight / 2 + 20;
        if (top < 10)
            top = 10;

        root.flyoutTop = top;
        _pendingCategory = categoryId;
        openDelayTimer.start();
    }
    function scheduleFlyoutClose() {
        flyoutCloseTimer.restart();
    }

    function cancelFlyoutClose() {
        flyoutCloseTimer.stop();
    }
    
    Timer {
        id: openDelayTimer

        interval: 50
        onTriggered: {
            root.flyoutCategory = root._pendingCategory;
            root._pendingCategory = "";
        }
    }



    Timer {
        id: flyoutCloseTimer

        interval: 250
        onTriggered: root.flyoutCategory = ""
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.topMargin: Appearance.padding.large
        anchors.bottomMargin: Appearance.padding.smaller
        spacing: 0

        SidebarHeader {
            z: 10
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.padding.normal
            session: root.session // qmllint disable incompatible-type
        }

        Flickable {
            id: navFlick

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Appearance.spacing.normal
            clip: true
            contentHeight: navColumn.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: navColumn

                width: navFlick.width
                spacing: Appearance.spacing.small

                Repeater {
                    model: NexusRegistry.getCategories()

                    delegate: Column {
                        id: catDelegate

                        required property var modelData
                        required property int index

                        readonly property string catId: modelData.id
                        readonly property bool hasChildren: modelData.children && modelData.children.length > 0

                        width: navColumn.width

                        SidebarNavItem {
                            session: root.session // qmllint disable incompatible-type
                            modelData: catDelegate.modelData
                            flyoutActive: root.flyoutCategory === catDelegate.catId
                            onFlyoutRequested: function (itemY) {
                                root.openFlyout(catDelegate.catId, itemY);
                            }
                            onFlyoutCloseRequested: root.scheduleFlyoutClose()
                        }

                        SidebarAccordion {
                            visible: !root.session.sidebarCollapsed && catDelegate.hasChildren
                            session: root.session // qmllint disable incompatible-type
                            childItems: catDelegate.hasChildren ? catDelegate.modelData.children : []
                            open: root.session.expandedCategory === catDelegate.catId
                        }
                    }
                }
            }
        }

        // Spacer
        Item {
            Layout.fillHeight: false
            Layout.preferredHeight: Appearance.spacing.large
        }

        // Bottom items
        Column {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Repeater {
                model: NexusRegistry.getBottomItems()

                delegate: SidebarBottomItem {
                    session: root.session // qmllint disable incompatible-type
                }
            }
        }

        // Separator above collapse toggle
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.bottomMargin: Appearance.spacing.normal
            Layout.topMargin: Appearance.spacing.normal
            Layout.leftMargin: Appearance.padding.large
            color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
        }

        // Collapse toggle
        Item {
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.padding.large / 1.5
            Layout.preferredHeight: 48

            StyledRect {
                width: parent.width
                height: 40
                radius: Appearance.rounding.full
                color: "transparent"

                Behavior on width {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }

                StateLayer {
                    function onClicked() {
                        root.session.toggleSidebar();
                    }

                    color: Colours.palette.m3onSurface
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.session.sidebarCollapsed ? "keyboard_double_arrow_right" : "keyboard_double_arrow_left"
                    color: Colours.palette.m3onSurface
                    font.pointSize: Appearance.font.size.large
                }
            }
        }
    }
}
