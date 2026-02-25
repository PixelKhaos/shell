//pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Effects

ListView {
    id: root

    clip: true
    model: LyricsService.model
    currentIndex: LyricsService.currentIndex

    visible: LyricsService.lyricsVisible && LyricsService.model.count != 0

    preferredHighlightBegin: height / 2 - 30
    preferredHighlightEnd: height / 2 + 30
    highlightRangeMode: ListView.ApplyRange
    highlightFollowsCurrentItem: true
    highlightMoveDuration: LyricsService.isManualSeeking ? 0 : Appearance.anim.durations.normal

    layer.enabled: true
    layer.effect: ShaderEffect {
        property var source: root
        property real fadeMargin: 0.5
        fragmentShader: "../../assets/shaders/fade.frag.qsb"
    }

    onModelChanged: {
        if (model && model.count > 0) {
            Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Center));
        }
    }

    delegate: Item {
        id: delegateRoot
        width: root.width

        readonly property bool hasContent: model.text && model.text.trim().length > 0
        height: hasContent ? (lyricText.contentHeight + Appearance.spacing.large) : 0

        property bool isCurrent: ListView.isCurrentItem

        MultiEffect {
            id: effect
            anchors.fill: lyricText
            source: lyricText
            scale: lyricText.scale
            enabled: delegateRoot.isCurrent
            visible: delegateRoot.isCurrent

            blurEnabled: true
            blur: 0.4

            shadowEnabled: true
            shadowColor: Colours.palette.m3primary
            shadowOpacity: 0.5
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0

            autoPaddingEnabled: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (model.time !== undefined) {
                    LyricsService.jumpTo(index, model.time);
                }
            }
        }

        Text {
            id: lyricText
            text: model.text ? model.text.replace(/\u00A0/g, " ") : ""
            width: parent.width * 0.85
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pointSize: Appearance.font.size.normal
            color: isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font.bold: isCurrent
            scale: isCurrent ? 1.15 : 1.0
            Behavior on color { ColorAnimation { duration: Appearance.anim.durations.small } }
            Behavior on scale { NumberAnimation { duration: Appearance.anim.durations.small; easing.type: Easing.OutCubic } }
        }
    }
}
