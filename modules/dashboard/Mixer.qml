pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import "../../components/controls"

Item {
    id: root
    clip: true
    
    // Required property for dashboard integration
    required property PersistentProperties visibilities
    
    property bool showDeviceSelector: false
    property bool deviceSelectorInput: false
    property int dialogMargins: 16
    property PwNode selectedDevice
    
    // Filter for application audio streams
    readonly property list<PwNode> appPwNodes: Pipewire.nodes.values.filter((node) => {
        return node.isSink && node.isStream
    })
    
    implicitWidth: volumeMixer.implicitWidth + Appearance.padding.large * 2
    implicitHeight: volumeMixer.implicitHeight + Appearance.padding.large * 2
    
    function showDeviceSelectorDialog(input) {
        root.selectedDevice = null
        root.showDeviceSelector = true
        root.deviceSelectorInput = input
    }
    
    Keys.onPressed: (event) => {
        // Close dialog on pressing Esc if open
        if (event.key === Qt.Key_Escape && root.showDeviceSelector) {
            root.showDeviceSelector = false
            event.accepted = true;
        }
    }
    
    StyledRect {
        id: volumeMixer
        anchors.centerIn: parent
        implicitWidth: Config.dashboard.sizes.mediaCoverArtSize * 4
        implicitHeight: Config.dashboard.sizes.mediaCoverArtSize * 1.5
        color: Colours.tPalette.m3surfaceContainerLow
        radius: Appearance.rounding.normal

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.large
            
            // Application streams
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                StyledListView {
                    id: listView
                    model: root.appPwNodes
                    clip: true
                    anchors {
                        fill: parent
                        topMargin: 10
                        bottomMargin: 10
                    }
                    spacing: 6

                    delegate: MixerEntry {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: 10
                            rightMargin: 10
                        }
                        required property var modelData
                        node: modelData
                    }
                }

                // Placeholder when list is empty
                Item {
                    anchors.fill: listView

                    visible: opacity > 0
                    opacity: (root.appPwNodes.length === 0) ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.anim.durations.normal
                            easing.type: Easing.InOutQuad
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: "volume_off"
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.large
                        }
                        
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("No audio source")
                        }
                    }
                }
            }
            
            // Device selector buttons
            RowLayout {
                id: deviceSelectorRowLayout
                Layout.fillWidth: true
                Layout.fillHeight: false
                spacing: Appearance.spacing.normal

                // Output device button
                Button {
                    id: outputButton
                    Layout.fillWidth: true
                    
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: parent.hovered ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainerHigh
                    }

                    implicitHeight: outputContent.implicitHeight + 12
                    implicitWidth: outputContent.implicitWidth + 12

                    onClicked: root.showDeviceSelectorDialog(false)

                    contentItem: RowLayout {
                        id: outputContent
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5

                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: false
                            Layout.leftMargin: 5
                            text: "media_output"
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.normal
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.rightMargin: 5
                            spacing: 0
                            
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Appearance.font.size.normal
                                text: qsTr("Output")
                                color: Colours.palette.m3onSurface
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Appearance.font.size.small
                                text: Pipewire.defaultAudioSink?.description || qsTr("Unknown")
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }

                // Input device button
                Button {
                    id: inputButton
                    Layout.fillWidth: true
                    
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: parent.hovered ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainerHigh
                    }

                    implicitHeight: inputContent.implicitHeight + 12
                    implicitWidth: inputContent.implicitWidth + 12

                    onClicked: root.showDeviceSelectorDialog(true)

                    contentItem: RowLayout {
                        id: inputContent
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5

                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: false
                            Layout.leftMargin: 5
                            text: "mic_external_on"
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.normal
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.rightMargin: 5
                            spacing: 0
                            
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Appearance.font.size.normal
                                text: qsTr("Input")
                                color: Colours.palette.m3onSurface
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Appearance.font.size.small
                                text: Pipewire.defaultAudioSource?.description || qsTr("Unknown")
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Device selector dialog
    StyledRect {
        id: deviceSelectorDialog
        anchors.centerIn: parent
        width: parent.width - root.dialogMargins * 2
        height: parent.height - root.dialogMargins * 2
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainerLow
        visible: root.showDeviceSelector
        z: 100
        
        Elevation {
            anchors.fill: parent
            radius: parent.radius
            level: 3
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal
                
                StyledText {
                    Layout.fillWidth: true
                    text: root.deviceSelectorInput ? qsTr("Select Input Device") : qsTr("Select Output Device")
                    font.pointSize: Appearance.font.size.normal
                    font.bold: true
                    color: Colours.palette.m3onSurface
                }
                
                MaterialIcon {
                    text: "close"
                    color: Colours.palette.m3onSurface
                    font.pointSize: Appearance.font.size.normal
                    
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        onClicked: root.showDeviceSelector = false
                    }
                }
            }
            
            // Device list
            StyledListView {
                id: deviceListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Appearance.spacing.small
                model: Pipewire.nodes.values.filter((node) => {
                    // Filter for sink (output) or source (input) devices based on dialog mode
                    return root.deviceSelectorInput ? node.isSource && !node.isStream : node.isSink && !node.isStream
                })
                
                delegate: Button {
                    id: delegateButton
                    required property var modelData
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    height: delegateContent.implicitHeight + 10
                    
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: delegateButton.hovered ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainerHigh
                    }
                    
                    onClicked: {
                        root.selectedDevice = modelData
                        if (root.deviceSelectorInput) {
                            Pipewire.preferredDefaultAudioSource = modelData
                        } else {
                            Pipewire.preferredDefaultAudioSink = modelData
                        }
                        root.showDeviceSelector = false
                    }
                    
                    contentItem: RowLayout {
                        id: delegateContent
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 10
                        
                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: root.deviceSelectorInput ? "mic" : "speaker"
                            color: Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.normal
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Appearance.font.size.normal
                                text: modelData.description || modelData.name || qsTr("Unknown Device")
                                color: Colours.palette.m3onSurface
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Appearance.font.size.small
                                text: modelData.properties ? modelData.properties["device.description"] || "" : ""
                                color: Colours.palette.m3onSurfaceVariant
                                visible: text !== ""
                            }
                        }
                        
                        // Selected indicator
                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: "check"
                            color: Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.normal
                            visible: (root.deviceSelectorInput && modelData === Pipewire.defaultAudioSource) || 
                                     (!root.deviceSelectorInput && modelData === Pipewire.defaultAudioSink)
                        }
                    }
                }
                
                // Empty state
                Item {
                    anchors.fill: parent
                    visible: deviceListView.count === 0
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.normal
                        
                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.deviceSelectorInput ? "mic_off" : "speaker_off"
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.large
                            opacity: 0.7
                        }
                        
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.deviceSelectorInput ? 
                                  qsTr("No input devices found") : 
                                  qsTr("No output devices found")
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.small
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
