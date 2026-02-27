pragma ComponentBehavior: Bound

import "services"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import Caelestia
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    property var currentItem: null
    property bool shouldShow: false

    property bool imageLoadError: false

    readonly property bool hasImage: {
        if (!currentItem?.modelData || imageLoadError)
            return false;
        const data = currentItem.modelData;
        return data.isImage === true || data.hasImageUrl === true;
    }

    property string imageDataUrl: ""
    property bool loadingImage: false
    property bool decodingHtml: false

    readonly property string imageSource: {
        if (!currentItem?.modelData)
            return "";
        const data = currentItem.modelData;

        if (data.isImage === true && imageDataUrl !== "")
            return imageDataUrl;
        if (data.hasImageUrl === true)
            return extractedImageUrl || data.imageUrl || "";

        return "";
    }

    property string extractedImageUrl: ""

    onCurrentItemChanged: {
        imageDataUrl = "";
        loadingImage = false;
        extractedImageUrl = "";
        imageLoadError = false;
        decodingHtml = false;

        if (currentItem && currentItem.modelData) {
            const data = currentItem.modelData;
            if (data.isImage === true) {
                loadingImage = true;
                decodeImageToDataUrl();
            } else if (data.needsDecodeForUrl === true) {
                // Need to decode full HTML to extract image URL
                decodingHtml = true;
                decodeHtmlForImageUrl();
            } else if (data.imageUrl) {
                extractedImageUrl = data.imageUrl;
            }
        }
    }

    function decodeImageToDataUrl(): void {
        if (!currentItem?.modelData || currentItem.modelData.isImage !== true)
            return;

        const data = currentItem.modelData;
        decodeProcess.command = ["sh", "-c", `cliphist decode ${data.id} | base64 -w 0`];
        decodeProcess.running = true;
    }

    function decodeHtmlForImageUrl(): void {
        if (!currentItem?.modelData || currentItem.modelData.needsDecodeForUrl !== true)
            return;

        const data = currentItem.modelData;
        decodeHtmlProcess.command = ["cliphist", "decode", data.id];
        decodeHtmlProcess.running = true;
    }

    Process {
        id: decodeProcess
        stdout: StdioCollector {}

        onExited: {
            if (root.currentItem?.modelData?.isImage === true) {
                const b64 = String(stdout.text).trim();
                if (b64)
                    root.imageDataUrl = "data:image/png;base64," + b64;
                root.loadingImage = false;
            }
        }
    }

    Process {
        id: copyGrabbedImageProcess
        stdout: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Toaster.toast("Image copied", "Copied image to clipboard", "image");
                // Refresh clipboard list
                Clipboard.refresh();
            } else {
                Toaster.toast("Copy failed", "Failed to copy image", "error");
            }
        }
    }

    Process {
        id: decodeHtmlProcess
        stdout: StdioCollector {}

        onExited: {
            root.decodingHtml = false;
            if (root.currentItem?.modelData?.needsDecodeForUrl === true) {
                const fullHtml = String(stdout.text);
                const srcMatch = fullHtml.match(/<img[^>]+src\s*=\s*["']([^"']+)["']/i);
                if (srcMatch?.[1])
                    root.extractedImageUrl = srcMatch[1];
            }
        }
    }

    readonly property real rounding: Config.border.rounding
    readonly property real targetHeight: {
        if (!shouldShow || !hasImage)
            return 0;

        if (previewImage.status === Image.Ready && previewImage.sourceSize.height > 0) {
            const aspectRatio = previewImage.sourceSize.width / previewImage.sourceSize.height;
            const maxHeight = 600;
            const minHeight = 200;
            const availableWidth = width - (Appearance.padding.normal * 2);
            const calculatedHeight = (availableWidth / aspectRatio) + (Appearance.padding.normal * 2);
            return Math.max(minHeight, Math.min(maxHeight, calculatedHeight));
        }

        return 400; // Default height while loading
    }

    width: 400
    height: targetHeight
    enabled: shouldShow && hasImage
    visible: height > 0
    clip: false

    Behavior on height {
        SequentialAnimation {
            Anim {
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }
    }

    Shape {
        id: backgroundShape
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

            // Bottom right inverse fillet
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
        anchors.leftMargin: (Appearance.padding.normal * 2) + (Appearance.padding.small / 2)
        anchors.topMargin: Appearance.padding.normal + (Appearance.padding.small / 2)
        anchors.rightMargin: Appearance.padding.normal / 2
        anchors.bottomMargin: Appearance.padding.normal
        spacing: 0

        Image {
            id: previewImage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            source: root.imageSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            opacity: root.shouldShow && root.hasImage ? 1 : 0

            onStatusChanged: {
                if (status === Image.Error) {
                    root.imageLoadError = true;
                }
            }

            Behavior on opacity {
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: {
                    if (root.loadingImage || (root.imageSource === "" && root.currentItem?.modelData?.isImage === true))
                        return "Decoding image...";
                    if (root.decodingHtml)
                        return "Extracting image URL...";
                    if (previewImage.status === Image.Loading)
                        return "Loading image...";
                    return "";
                }
                horizontalAlignment: Text.AlignHCenter
                color: Colours.palette.m3onSurfaceVariant
                visible: text !== ""
            }
        }
    }

    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Appearance.padding.normal + Appearance.padding.small
        anchors.rightMargin: Appearance.padding.normal + Appearance.padding.small
        z: 10
        icon: "content_copy"
        type: IconButton.Filled
        visible: {
            if (!root.currentItem?.modelData)
                return false;
            const data = root.currentItem.modelData;
            return (data.hasImageUrl === true || data.needsDecodeForUrl === true) && root.extractedImageUrl !== "" && previewImage.status === Image.Ready;
        }
        onClicked: {
            // Grab the loaded image and save to temp file, then copy to clipboard
            previewImage.grabToImage(function (result) {
                const tempPath = "/tmp/quickshell-clipboard-grab-" + Date.now() + ".png";
                if (result.saveToFile(tempPath)) {
                    // Copy the saved image to clipboard
                    const cmd = `wl-copy < '${tempPath}' --type image/png && rm '${tempPath}'`;
                    copyGrabbedImageProcess.command = ["sh", "-c", cmd];
                    copyGrabbedImageProcess.running = true;
                }
            });
        }
    }
}
