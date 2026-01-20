pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    property var currentItem: null
    property bool shouldShow: false

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

    readonly property real rounding: Config.border.rounding
    readonly property real targetHeight: shouldShow && hasImage ? 400 : 0

    width: 400
    height: targetHeight
    enabled: shouldShow && hasImage
    visible: height > 0
    clip: true
    
    Behavior on height {
        SequentialAnimation {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        
        ShapePath {
            strokeWidth: -1
            fillColor: Colours.palette.m3surface
            
            // Start at bottom left
            startX: 0
            startY: root.height
            
            // Bottom left inverse arc
            PathArc {
                relativeX: root.rounding
                relativeY: -root.rounding
                radiusX: root.rounding
                radiusY: root.rounding
                direction: PathArc.Counterclockwise
            }
            
            // Left edge going up
            PathLine {
                relativeX: 0
                relativeY: -(root.height - root.rounding * 2)
            }
            
            // Top left rounded corner
            PathArc {
                relativeX: root.rounding
                relativeY: -root.rounding
                radiusX: root.rounding
                radiusY: root.rounding
            }
            
            // Top edge
            PathLine {
                relativeX: root.width - root.rounding * 2
                relativeY: 0
            }
            
            // Top right rounded corner
            PathArc {
                relativeX: root.rounding
                relativeY: root.rounding
                radiusX: root.rounding
                radiusY: root.rounding
            }
            
            // Right edge going down
            PathLine {
                relativeX: 0
                relativeY: root.height - root.rounding * 2
            }
            
            // Bottom right inverse arc
            PathArc {
                relativeX: root.rounding
                relativeY: root.rounding
                radiusX: root.rounding
                radiusY: root.rounding
                direction: PathArc.Counterclockwise
            }
            
            Behavior on fillColor {
                CAnim {}
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        anchors.topMargin: Appearance.padding.normal + root.rounding
        anchors.bottomMargin: Appearance.padding.normal + root.rounding
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
                text: "Image preview"
                horizontalAlignment: Text.AlignHCenter
                color: Colours.palette.m3onSurfaceVariant
            }

            // TODO: Implement actual image preview using wl-paste
        }
    }
}
