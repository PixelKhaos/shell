pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.config
import qs.modules.nexus

Item {
    id: root

    required property NexusSession session

    property string flyoutCategory: ""
    property bool open: false
    readonly property var currentCat: flyoutCategory !== "" ? NexusRegistry.getById(flyoutCategory) : null
    readonly property int childCount: currentCat?.children?.length ?? 0

    property string _prevCategory: ""
    property var _prevCat: null

    signal hoverEntered
    signal hoverExited
    signal childClicked(string id)

    implicitWidth: drawer.targetWidth + 2
    implicitHeight: drawer.targetHeight

    onFlyoutCategoryChanged: {
        if (flyoutCategory !== "" && flyoutCategory !== _prevCategory) {
            contentFadeOut.start();
        }
    }

    Rectangle {
        id: drawer

        property real targetWidth: 100
        property real targetHeight: (root.currentCat?.children?.length ?? 0) * 68 + 46 || 80

        width: root.open ? targetWidth : 0
        height: targetHeight
        clip: true
        color: Colours.tPalette.m3surfaceContainer
        radius: 0
        topRightRadius: Appearance.rounding.small
        bottomRightRadius: Appearance.rounding.small

        Behavior on width {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.hoverEntered();
                else
                    root.hoverExited();
            }
        }

        Item {
            id: contentContainer

            anchors.fill: parent
            anchors.margins: 12
            opacity: 1

            NumberAnimation {
                id: contentFadeOut

                target: contentContainer
                property: "opacity"
                from: 1
                to: 0
                duration: 80
                onFinished: {
                    root._prevCategory = root.flyoutCategory;
                    root._prevCat = root.currentCat;
                    contentFadeIn.start();
                }
            }

            NumberAnimation {
                id: contentFadeIn

                target: contentContainer
                property: "opacity"
                from: 0
                to: 1
                duration: 150
            }

            // Category label
            StyledText {
                id: flyoutLabel

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                text: root.currentCat ? root.currentCat.label : ""
                color: Qt.alpha(Colours.palette.m3onSurface, 0.35)
                font.pointSize: Appearance.font.size.small - 1
                font.capitalization: Font.AllUppercase
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                id: childColumn

                anchors.top: flyoutLabel.bottom
                anchors.topMargin: 6
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 6

                Repeater {
                    model: root.currentCat && root.currentCat.children ? root.currentCat.children : []

                    delegate: Item {
                        id: flyoutChild

                        required property var modelData

                        readonly property bool isActive: root.session.activeCategory === flyoutChild.modelData.id

                        width: childColumn.width
                        height: 64

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.normal
                            color: flyoutChild.isActive ? Qt.alpha(Colours.palette.m3primary, 0.16) : "transparent"

                            Behavior on color {
                                CAnim {}
                            }

                            StateLayer {
                                function onClicked() {
                                    root.childClicked(flyoutChild.modelData.id);
                                }

                                radius: Appearance.rounding.normal
                                color: flyoutChild.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 3

                                MaterialIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: flyoutChild.modelData.icon
                                    color: flyoutChild.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                    font.pointSize: Appearance.font.size.larger
                                    fill: flyoutChild.isActive ? 1 : 0

                                    Behavior on fill {
                                        Anim {}
                                    }
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: flyoutChild.modelData.label.length > 12 ? flyoutChild.modelData.label.substring(0, 11) + "…" : flyoutChild.modelData.label
                                    color: flyoutChild.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                                    font.pointSize: Appearance.font.size.small - 1
                                    font.capitalization: Font.Capitalize
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
