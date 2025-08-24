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

Item {
    id: root
    required property PwNode node
    property int leftPadding: 0
    
    
    implicitHeight: rowLayout.implicitHeight
    
    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.leftMargin: root.leftPadding
        spacing: 6
        
        Image {
            property real fixedSize: 24
            Layout.preferredWidth: fixedSize
            Layout.preferredHeight: fixedSize
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: source != ""
            sourceSize.width: fixedSize
            sourceSize.height: fixedSize
            source: {
                if (!root.node || !root.node.properties) return "";
                
                let icon;
                icon = root.node.properties["application.icon-name"];
                if (icon && Quickshell.iconExists(icon))
                    return Quickshell.iconPath(icon, "image-missing");
                    
                icon = root.node.properties["node.name"];
                if (icon)
                    return Quickshell.iconPath(icon, "image-missing");
                    
                return "";
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: -4
            
            StyledText {
                Layout.fillWidth: true
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
                text: {
                    if (!root.node || !root.node.properties) return "Unknown";
                    
                    // application.name -> description -> name
                    const app = root.node.properties["application.name"] || 
                               (root.node.description && root.node.description !== "" ? 
                                root.node.description : root.node.name);
                    const media = root.node.properties["media.name"];
                    return media ? `${app} • ${media}` : app;
                }
            }
            
            VolumeSlider {
                id: slider
                Layout.fillWidth: true
                showIcon: false
                muted: root.node && root.node.audio && root.node.ready ? root.node.audio.muted : false
                value: root.node && root.node.audio && root.node.ready ? root.node.audio.volume : 0
                onValueChanged: {
                    if (root.node && root.node.audio && root.node.ready) {
                        root.node.audio.volume = value;
                    }
                }
            }
        }
        
        // Mute button
        MaterialIcon {
            id: muteButton
            text: root.node && root.node.audio && root.node.ready && root.node.audio.muted ? "volume_off" : "volume_up"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.normal
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (root.node && root.node.audio && root.node.ready) {
                        root.node.audio.muted = !root.node.audio.muted;
                    }
                }
            }
        }
    }
}
