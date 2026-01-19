pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var currentItem: null

    readonly property bool hasImage: {
        if (!currentItem || !currentItem.modelData || !currentItem.modelData.content)
            return false;
        const content = currentItem.modelData.content;
        
        // Check for image MIME types or binary indicators
        return content.includes("image/") || 
               content.includes("[[ binary data") ||
               content.includes("[[") ||
               content.length > 500; // Large content might be binary
    }

    width: 400
    height: 400

    StyledRect {
        anchors.fill: parent
        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Appearance.rounding.large

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                text: "Image Preview"
                font.pointSize: Appearance.font.size.normal
                font.weight: Font.Medium
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StyledText {
                    anchors.centerIn: parent
                    text: "Image preview\n(requires wl-paste)"
                    horizontalAlignment: Text.AlignHCenter
                    color: Colours.palette.m3onSurfaceVariant
                }

                // TODO: Implement actual image preview using wl-paste
                // This would require decoding the clipboard image data
            }
        }
    }

    Behavior on opacity {
        CAnim {}
    }
}
