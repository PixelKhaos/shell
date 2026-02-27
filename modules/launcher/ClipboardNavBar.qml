pragma ComponentBehavior: Bound

import "../../components" as Components
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Components.TabNavbar {
    id: root

    required property var clipboardList

    readonly property var categoryList: [
        {
            id: "all",
            name: qsTr("All"),
            icon: "apps"
        },
        {
            id: "images",
            name: qsTr("Images"),
            icon: "image"
        },
        {
            id: "misc",
            name: qsTr("Misc"),
            icon: "description"
        }
    ]

    tabs: root.categoryList
    activeTab: root.clipboardList?.activeCategory ?? "all"
    showScrollButtons: false
    showExtraContent: true

    onTabChanged: tabId => {
        if (root.clipboardList) {
            root.clipboardList.activeCategory = tabId;
        }
    }

    extraContent: Component {
        RowLayout {
            spacing: Appearance.spacing.small

            StyledText {
                text: root.clipboardList ? qsTr("%1 items").arg(root.clipboardList.count) : ""
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
                opacity: root.clipboardList?.count > 0 ? 1 : 0

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.small
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }

            IconButton {
                icon: "delete_sweep"
                type: IconButton.Text
                radius: Appearance.rounding.small
                padding: Appearance.padding.small
                onClicked: {
                    if (root.clipboardList) {
                        root.clipboardList.showClearConfirmation = true;
                    }
                }
            }
        }
    }
}
