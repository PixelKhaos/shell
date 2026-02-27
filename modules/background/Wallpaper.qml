pragma ComponentBehavior: Bound

import qs.components
import qs.components.filedialog
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root
    anchors.fill: parent
    required property ShellScreen screen

    // Current wallpaper path (managed by Caelestia)
    property string source: Wallpapers.current
    property bool initialized: false
    property int loadedCount: 0
    property bool itemsReady: false
    property bool initStarted: false
    property bool gamemodeEnabled: GameMode.enabled
    property var sessionLock: null
    readonly property bool sessionLocked: sessionLock ? sessionLock.secure : false
    property bool shouldPause: Config.background.wallpaper.video.autoPause && !(Hypr.monitorFor(screen)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true)

    function applySessionLock(loader) {
        if (!loader || !loader.item)
            return;

        if (typeof loader.item.pausePlayVideo === "function")
            loader.item.pausePlayVideo(sessionLocked);
    }

    function autoPauseVideo(loader) {
        if (!loader || !loader.item)
            return;

        const pause = root.shouldPause && !root.gamemodeEnabled;

        if (typeof loader.item.shouldPause === "boolean")
            loader.item.shouldPause = pause;
    }

    function isVideo(path) {
        path = path.toString();
        if (!path || path.trim() === "")
            return false;

        const videoExtensions = [".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".wmv", ".gif"];

        const lower = path.toLowerCase();
        for (let i = 0; i < videoExtensions.length; i++) {
            if (lower.endsWith(videoExtensions[i]))
                return true;
        }
        return false;
    }

    function waitForBothItems() {
        if (oneLoader.item && twoLoader.item) {
            itemsReady = true;
            initialize();
            return;
        }
        Qt.callLater(waitForBothItems);
    }

    function initialize() {
        if (initStarted || loadedCount < 2 || !itemsReady)
            return;

        initStarted = true;

        oneLoader.item.isCurrent = true;
        twoLoader.item.isCurrent = false;

        initialized = true;
        Qt.callLater(switchWallpaper);
    }

    function switchWallpaper() {
        if (!initialized || !root.source)
            return;

        let active;
        let inactive;

        if (oneLoader.item.isCurrent) {
            active = oneLoader;
            inactive = twoLoader;
        } else {
            active = twoLoader;
            inactive = oneLoader;
        }

        if (inactive.item && inactive.item.slotId !== undefined && inactive.item.slotId >= 0) {
            DecoderService.stopSlot(inactive.item.slotId);
        }

        inactive.sourceComponent = null;
        Qt.callLater(() => {
            if (isVideo(source)) {
                inactive.sourceComponent = Config.background.wallpaper.video.useExternalDecoder ? videoDecoderComponent : videoComponent;
            } else {
                inactive.sourceComponent = imageComponent;
            }
        });

        waitForItem(inactive, function () {
            if (inactive.item.slotId !== undefined) {
                const newSlotId = (inactive === oneLoader) ? 0 : 1;
                inactive.item.slotId = newSlotId;
            }

            Qt.callLater(() => {
                inactive.item.update(source);

                inactive.item.ready.connect(function handler() {
                    inactive.z = 1;
                    active.z = 0;

                    inactive.item.isCurrent = true;

                    const timer = Qt.createQmlObject('import QtQuick; Timer { interval: ' + Appearance.anim.durations.normal + '; repeat: false }', root);
                    timer.triggered.connect(() => {
                        active.item.isCurrent = false;
                        timer.destroy();
                    });
                    timer.start();

                    inactive.item.ready.disconnect(handler);
                });
            });
        });
    }

    function waitForItem(loader, callback) {
        if (loader.item) {
            callback();
            return;
        }
        Qt.callLater(() => waitForItem(loader, callback));
    }

    onSessionLockedChanged: {
        applySessionLock(oneLoader);
        applySessionLock(twoLoader);
    }

    onShouldPauseChanged: {
        autoPauseVideo(oneLoader);
        autoPauseVideo(twoLoader);
    }

    Loader {
        id: placeholderLoader
        anchors.fill: parent
        active: !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Appearance.spacing.large

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.extraLarge * 5
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.extraLarge * 2
                        font.bold: true
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: selectWallText.implicitHeight + Appearance.padding.small * 2

                        radius: Appearance.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog
                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Files")
                            filters: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg", "mp4", "mkv", "webm", "avi", "mov", "flv", "wmv", "gif"]
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            function onClicked(): void {
                                dialog.open();
                            }
                        }

                        StyledText {
                            id: selectWallText
                            anchors.centerIn: parent
                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Appearance.font.size.large
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: oneLoader
        anchors.fill: parent
        asynchronous: true
        sourceComponent: imageComponent
        z: 1
        onLoaded: {
            root.loadedCount++;
            if (root.loadedCount === 2)
                root.waitForBothItems();
        }

        onItemChanged: {
            root.applySessionLock(oneLoader);
            root.autoPauseVideo(oneLoader);
        }
    }

    Loader {
        id: twoLoader
        anchors.fill: parent
        asynchronous: true
        sourceComponent: imageComponent
        z: 0
        onLoaded: {
            root.loadedCount++;
            if (root.loadedCount === 2)
                root.waitForBothItems();
        }

        onItemChanged: {
            root.applySessionLock(oneLoader);
            root.autoPauseVideo(twoLoader);
        }
    }

    onSourceChanged: {
        if (initialized)
            switchWallpaper();
    }

    Component {
        id: imageComponent
        ImageWallpaper {}
    }

    Component {
        id: videoComponent
        VideoWallpaper {}
    }

    Component {
        id: videoDecoderComponent
        VideoWallpaperDecoder {}
    }
}
