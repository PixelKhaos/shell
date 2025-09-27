pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var props
    required property var visibilities

    property bool isScreenshotMode: root.props.captureMode

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            // Mode switcher icons
            Row {
                spacing: Appearance.spacing.small

                IconButton {
                    id: screenshotModeBtn
                    icon: "screenshot"
                    type: root.isScreenshotMode ? IconButton.Filled : IconButton.Text
                    onClicked: root.props.captureMode = true
                }

                IconButton {
                    id: recordModeBtn
                    icon: "videocam"
                    type: !root.isScreenshotMode ? IconButton.Filled : IconButton.Text
                    onClicked: root.props.captureMode = false
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.isScreenshotMode ? qsTr("Screenshots") : qsTr("Screen Recorder")
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.isScreenshotMode 
                        ? qsTr("Capture an area or the screen and edit in Swappy")
                        : (Recorder.paused ? qsTr("Recording paused") : Recorder.running ? qsTr("Recording running") : qsTr("Recording off"))
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(
                screenshotContentItem.implicitHeight, 
                recordContentItem.implicitHeight
            )
            
            // Screenshot content
            ColumnLayout {
                id: screenshotContentItem
                anchors.fill: parent
                spacing: Appearance.spacing.normal
                opacity: root.isScreenshotMode ? 1 : 0
                visible: opacity > 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
                
                SplitButton {
                    id: screenshotSplit
                    Layout.fillWidth: true
                    z: 2
                    disabled: false
                    active: menuItems.find(m => root.props.screenshotMode === m.icon + m.text) ?? menuItems[0]
                    menu.onItemSelected: item => root.props.screenshotMode = item.icon + item.text
                    stateLayer.disabled: false

                    menuItems: [
                        MenuItem {
                            icon: "screenshot"
                            text: qsTr("Region/Window")
                            activeText: qsTr("Region")
                            onClicked: {
                                root.visibilities.utilities = false;
                                root.visibilities.sidebar = false;
                                Quickshell.execDetached(["caelestia", "screenshot", "--freeze", "--region"]);
                            }
                        },
                        MenuItem {
                            icon: "fullscreen"
                            text: qsTr("Fullscreen")
                            activeText: qsTr("Screen")
                            onClicked: {
                                root.visibilities.utilities = false;
                                root.visibilities.sidebar = false;
                                Quickshell.execDetached(["caelestia", "screenshot", "--freeze"]);
                            }
                        }
                    ]
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    sourceComponent: screenshotList
                }
            }
            
            // Record content
            ColumnLayout {
                id: recordContentItem
                anchors.fill: parent
                spacing: Appearance.spacing.normal
                opacity: !root.isScreenshotMode ? 1 : 0
                visible: opacity > 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
                
                SplitButton {
                    Layout.fillWidth: true
                    z: 2
                    disabled: Recorder.running
                    active: menuItems.find(m => root.props.recordingMode === m.icon + m.text) ?? menuItems[0]
                    menu.onItemSelected: item => root.props.recordingMode = item.icon + item.text

                    menuItems: [
                        MenuItem {
                            icon: "fullscreen"
                            text: qsTr("Record fullscreen")
                            activeText: qsTr("Fullscreen")
                            onClicked: Recorder.start()
                        },
                        MenuItem {
                            icon: "screenshot_region"
                            text: qsTr("Record region")
                            activeText: qsTr("Region")
                            onClicked: Recorder.start(["-r"])
                        }
                    ]
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: Recorder.running

                    IconButton {
                        Layout.fillWidth: true
                        icon: Recorder.paused ? "play_arrow" : "pause"
                        type: IconButton.Tonal
                        onClicked: Recorder.paused ? Recorder.resume() : Recorder.pause()
                    }

                    IconButton {
                        Layout.fillWidth: true
                        icon: "stop"
                        type: IconButton.Tonal
                        inactiveColour: Colours.palette.m3error
                        inactiveOnColour: Colours.palette.m3onError
                        onClicked: Recorder.stop()
                    }
                }
                
                Loader {
                    Layout.fillWidth: true
                    active: !Recorder.running
                    asynchronous: true
                    
                    sourceComponent: recordingList
                }
            }
        }
    }


    Timer {
        id: delayTimer
        interval: 200
        onTriggered: Quickshell.spawn(pendingCommand)
    }
    
    property var pendingCommand: []

    Component {
        id: screenshotList

        ScreenshotList {
            props: root.props
            visibilities: root.visibilities
        }
    }
    
    Component {
        id: recordingList

        RecordingList {
            props: root.props
            visibilities: root.visibilities
        }
    }
}
