pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Caelestia
import QtQuick

Item {
    id: root
    anchors.fill: parent
    signal ready
    property bool shouldPause: false
    property bool isCurrent: false
    property string source: ""
    property bool gamemodeEnabled: GameMode.enabled
    property bool pendingUnload: false
    property int slotId: -1
    property string visualMode: !root.isCurrent ? "none" : gamemodeEnabled ? "placeholder" : "video"
    property var slotTimer: null
    property var fallbackTimer: null

    function update(path) {
        if (gamemodeEnabled) {
            root.source = path;
            Qt.callLater(root.ready);
            return;
        }

        path = path.toString();
        if (!path || path.trim() === "")
            return;

        root.source = path;
        root.hasSignaledReady = false;

        if (root.slotTimer)
            root.slotTimer.destroy();
        if (root.fallbackTimer)
            root.fallbackTimer.destroy();

        videoFrame.slot = -1;
        const targetSlot = slotId;
        DecoderService.loadVideo(targetSlot, path, function () {
            root.slotTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 75; repeat: false }', root);
            root.slotTimer.triggered.connect(() => {
                videoFrame.slot = targetSlot;

                root.fallbackTimer = Qt.createQmlObject('import QtQuick; Timer { interval: 25; repeat: false }', root);
                root.fallbackTimer.triggered.connect(() => {
                    if (!root.hasSignaledReady && root.source) {
                        root.hasSignaledReady = true;

                        const timer = Qt.createQmlObject('import QtQuick; Timer { interval: 100; repeat: false }', root);
                        timer.triggered.connect(() => {
                            root.ready();
                            timer.destroy();
                        });
                        timer.start();
                    }
                });
                root.fallbackTimer.start();
            });
            root.slotTimer.start();
        });
    }

    function pausePlayVideo(shouldPause) {
        if (gamemodeEnabled)
            return;
        if (!isCurrent)
            return;

        if (shouldPause || root.shouldPause) {
            DecoderService.pauseSlot(slotId);
        } else {
            DecoderService.resumeSlot(slotId);
        }
    }

    onIsCurrentChanged: {
        if (!root.isCurrent && root.slotId >= 0) {
            DecoderService.stopSlot(root.slotId);
        }
    }

    onShouldPauseChanged: {
        pausePlayVideo(root.shouldPause);
    }

    onGamemodeEnabledChanged: {
        if (gamemodeEnabled) {
            DecoderService.stopSlot(slotId);
            pendingUnload = true;
        } else if (root.isCurrent && root.source) {
            update(root.source);
        }
    }

    property bool hasSignaledReady: false

    Component.onDestruction: {
        if (slotId >= 0) {
            DecoderService.stopSlot(slotId);
        }
    }

    VideoFrameItem {
        id: videoFrame
        anchors.fill: parent
        visible: root.visualMode === "video"
        opacity: root.isCurrent ? 1.0 : 0.0
        pollRate: {
            const refreshRate = root.screen?.refreshRate ?? 60;
            return Math.round(1000 / refreshRate);
        }
        scale: (root.isCurrent ? 1 : Wallpapers.showPreview ? 1 : 0.8)

        onFrameReady: {
            if (!root.hasSignaledReady && root.source) {
                root.hasSignaledReady = true;

                const timer = Qt.createQmlObject('import QtQuick; Timer { interval: 50; repeat: false }', root);
                timer.triggered.connect(() => {
                    root.ready();
                    timer.destroy();
                });
                timer.start();
            }
        }

        Behavior on opacity {
            Anim {
                onRunningChanged: {
                    if (running)
                        return;
                    if (root.pendingUnload && videoFrame.opacity === 0) {
                        DecoderService.stopSlot(root.slotId);
                        root.pendingUnload = false;
                    }
                }
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    StyledRect {
        id: gameModePlaceholder
        opacity: root.visualMode === "placeholder" ? 1 : 0
        anchors.fill: parent
        color: Colours.palette.m3surfaceContainer

        Behavior on opacity {
            Anim {}
        }

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spacing.large

            MaterialIcon {
                text: "stadia_controller"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.extraLarge * 5
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.small

                StyledText {
                    text: qsTr("Video wallpapers are disabled in game mode")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.extraLarge
                    font.bold: true
                }
            }
        }
    }

    Connections {
        target: root
        function onIsCurrentChanged() {
            pausePlayVideo(root.shouldPause);
        }
    }
}
