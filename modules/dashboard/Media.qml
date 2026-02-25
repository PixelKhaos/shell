//pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.config
import Caelestia.Services
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import "../../utils/scripts/lrcparser.js" as Lrc

Item {
    id: root

    required property PersistentProperties visibilities
    
    property bool lyricMenuOpen: false

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    implicitWidth: cover.implicitWidth + Config.dashboard.sizes.mediaVisualiserSize * 2 + details.implicitWidth + details.anchors.leftMargin + bongocat.implicitWidth + bongocat.anchors.leftMargin * 2 + Appearance.padding.large * 2
    implicitHeight: Math.max(
    cover.implicitHeight + Config.dashboard.sizes.mediaVisualiserSize * 2,
    visibilities.lyricMenu ? lyricMenu.implicitHeight : details.implicitHeight,
    bongocat.implicitHeight
    ) + Appearance.padding.large * 2

    Behavior on playerProgress {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            if (!Players.active) return;
            LyricsService.updatePosition();
            Players.active?.positionChanged();
        }
    }

    ServiceRef {
        service: Audio.cava
    }

    ServiceRef {
        service: Audio.beatTracker
    }

    Shape {
        id: visualiser

        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real innerX: cover.implicitWidth / 2 + Appearance.spacing.small
        readonly property real innerY: cover.implicitHeight / 2 + Appearance.spacing.small
        property color colour: Colours.palette.m3primary

        anchors.fill: cover
        anchors.margins: -Config.dashboard.sizes.mediaVisualiserSize

        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        data: visualiserBars.instances
    }

    Variants {
        id: visualiserBars

        model: Array.from({
            length: Config.services.visualiserBars
        }, (_, i) => i)

        ShapePath {
            id: visualiserBar

            required property int modelData
            readonly property real value: Math.max(1e-3, Math.min(1, Audio.cava.values[modelData]))

            readonly property real angle: modelData * 2 * Math.PI / Config.services.visualiserBars
            readonly property real magnitude: value * Config.dashboard.sizes.mediaVisualiserSize
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap
            strokeWidth: 360 / Config.services.visualiserBars - Appearance.spacing.small / 4
            strokeColor: Colours.palette.m3primary

            startX: visualiser.centerX + (visualiser.innerX + strokeWidth / 2) * cos
            startY: visualiser.centerY + (visualiser.innerY + strokeWidth / 2) * sin

            PathLine {
                x: visualiser.centerX + (visualiser.innerX + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.cos
                y: visualiser.centerY + (visualiser.innerY + visualiserBar.strokeWidth / 2 + visualiserBar.magnitude) * visualiserBar.sin
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Appearance.padding.large + Config.dashboard.sizes.mediaVisualiserSize

        implicitWidth: Config.dashboard.sizes.mediaCoverArtSize
        implicitHeight: Config.dashboard.sizes.mediaCoverArtSize

        color: Colours.tPalette.m3surfaceContainerHigh
        radius: Infinity

        MaterialIcon {
            anchors.centerIn: parent

            grade: 200
            text: "art_track"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: (parent.width * 0.4) || 1
        }

        Image {
            id: image

            anchors.fill: parent

            source: Players.active?.trackArtUrl ?? "" // qmllint disable incompatible-type
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            sourceSize.height: height

            MouseArea{
                anchors.fill: parent
                onClicked: {
                    LyricsService.lyricsVisible = !LyricsService.lyricsVisible
                }
            }

        }
    }

    ColumnLayout {
        id: details

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: visualiser.right
        anchors.leftMargin: Appearance.spacing.normal

        spacing: Appearance.spacing.small

        StyledText {
            id: title

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
            color: Players.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            font.pointSize: Appearance.font.size.normal
            elide: Text.ElideRight
        }

        StyledText {
            id: album

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            visible: !!Players.active
            text: Players.active?.trackAlbum || qsTr("Unknown album")
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.small
            elide: Text.ElideRight
        }

        StyledText {
            id: artist

            Layout.fillWidth: true
            Layout.maximumWidth: parent.implicitWidth

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (Players.active?.trackArtist ?? qsTr("Play some music for stuff to show up here!")) || qsTr("Unknown artist")
            color: Players.active ? Colours.palette.m3secondary : Colours.palette.m3outline
            elide: Text.ElideRight
            wrapMode: Players.active ? Text.NoWrap : Text.WordWrap
        }

        ListView {
            id: lyricsView
            Layout.fillWidth: true
            Layout.preferredHeight: 200
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
                property var source: lyricsView
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
                width: lyricsView.width

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
                    width: parent.width*0.85 //to make up for the size increase on scaling
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

        RowLayout {
            id: controls

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Appearance.spacing.small
            Layout.bottomMargin: Appearance.spacing.smaller

            spacing: Appearance.spacing.small

            PlayerControl {
                type: IconButton.Text
                icon: Players.active?.shuffle ? "shuffle_on" : "shuffle"
                font.pointSize: Math.round(Appearance.font.size.large)
                disabled: !Players.active?.shuffleSupported
                onClicked: Players.active.shuffle = !Players.active?.shuffle
            }

            PlayerControl {
                type: IconButton.Text
                icon: "skip_previous"
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canGoPrevious
                onClicked: Players.active?.previous()
            }

            PlayerControl {
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                label.animate: true
                toggle: true
                padding: Appearance.padding.small / 2
                checked: Players.active?.isPlaying ?? false
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
            }

            PlayerControl {
                type: IconButton.Text
                icon: "skip_next"
                font.pointSize: Math.round(Appearance.font.size.large * 1.5)
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }

            PlayerControl {
                type: IconButton.Text
                icon: "lyrics"
                font.pointSize: Math.round(Appearance.font.size.large)
                onClicked: root.lyricMenuOpen = !root.lyricMenuOpen
            }
        }

        StyledSlider {
            id: slider

            enabled: !!Players.active
            implicitWidth: 280
            implicitHeight: Appearance.padding.normal * 3

            onMoved: {
                const active = Players.active;
                if (active?.canSeek && active?.positionSupported)
                    active.position = value * active.length;
            }

            Binding {
                target: slider
                property: "value"
                value: root.playerProgress
                when: !slider.pressed
            }

            CustomMouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton

                function onWheel(event: WheelEvent) {
                    const active = Players.active;
                    if (!active?.canSeek || !active?.positionSupported)
                        return;

                    event.accepted = true;
                    const delta = event.angleDelta.y > 0 ? 10 : -10;    // Time 10 seconds
                    Qt.callLater(() => {
                        active.position = Math.max(0, Math.min(active.length, active.position + delta));
                    });
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: Math.max(position.implicitHeight, length.implicitHeight)

            StyledText {
                id: position

                anchors.left: parent.left

                text: root.lengthStr(Players.active?.position ?? -1)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                id: length

                anchors.right: parent.right

                text: root.lengthStr(Players.active?.length ?? -1)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }
        }
    }

    ColumnLayout {
        id: leftSection

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: details.right
        anchors.leftMargin: Appearance.spacing.normal
        
        visible: !root.lyricMenuOpen

        Item {
            id: bongocat

            implicitWidth: visualiser.width
            implicitHeight: visualiser.height

            AnimatedImage {
                anchors.centerIn: parent

                width: visualiser.width * 0.75
                height: visualiser.height * 0.75

                playing: Players.active?.isPlaying ?? false
                speed: Audio.beatTracker.bpm / Appearance.anim.mediaGifSpeedAdjustment // qmllint disable unresolved-type
                source: Paths.absolutePath(Config.paths.mediaGif)
                asynchronous: true
                fillMode: AnimatedImage.PreserveAspectFit
            }
        }
    }

    StyledRect {
        id: lyricMenu

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: details.right
        anchors.right: parent.right
        anchors.leftMargin: Appearance.spacing.normal 

        Layout.fillWidth: true
        implicitHeight: LyricsService.model.count == 0 || !LyricsService.lyricsVisible ? details.height + Appearance.padding.large * 5 : details.height
        width: 200

        radius: Appearance.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        visible: root.lyricMenuOpen 
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.padding.small 

                MaterialIcon {
                    text: "lyrics"
                    fill: 1
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.spacing.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: LyricsService.backend
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3secondary
                    elide: Text.ElideRight
                }

                IconButton {
                    icon: "refresh"
                    type: IconButton.Text
                    onClicked: LyricsService.loadLyrics()
                }

                StyledSwitch {
                    checked: LyricsService.lyricsVisible
                    onToggled: LyricsService.lyricsVisible = !LyricsService.lyricsVisible
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Fetched Candidates:"
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
                elide: Text.ElideRight
            }
            
            ListView {
                id: candidatesView

                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: LyricsService.candidatesModel.count > 0
                model: LyricsService.candidatesModel
                clip: true
                spacing: Appearance.spacing.small

                opacity: visible ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Appearance.anim.durations.normal }
                }

                delegate: Item {
                    id: delegateRoot
                    width: candidatesView.width*0.98
                    height: 70
                    anchors.horizontalCenter: parent.horizontalCenter

                    property bool hovered: false
                    property bool pressed: false

                    scale: hovered ? 1.02 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: Appearance.anim.durations.small
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: background
                        anchors.fill: parent
                        radius: 16

                        color: pressed
                        ? Qt.rgba(Colours.palette.m3primary.r,
                                  Colours.palette.m3primary.g,
                                  Colours.palette.m3primary.b, 0.25)
                        : hovered
                        ? Qt.rgba(1,1,1,0.06)
                        : Qt.rgba(1,1,1,0.03)

                        border.width: hovered ? 1 : 0
                        border.color: Colours.palette.m3primary

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.width { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: delegateRoot.hovered = true
                        onExited: delegateRoot.hovered = false

                        onPressed: delegateRoot.pressed = true
                        onReleased: delegateRoot.pressed = false

                        onClicked: {
                            LyricsService.selectCandidate(model.id)
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14
                        Layout.fillWidth: true

                        // Accent indicator bar
                        Rectangle {
                            width: 4
                            height: parent.height * 0.6
                            radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: LyricsService.currentSongId == model.id ? Colours.palette.m3primary : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 30
                            spacing: 4

                            Text {
                                text: model.title
                                font.pointSize: Appearance.font.size.normal
                                font.bold: true
                                color: hovered
                                ? Colours.palette.m3primary
                                : Colours.palette.m3onSurface
                                width: parent.width
                                elide: Text.ElideRight

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            Text {
                                text: model.artist
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                visible: LyricsService.candidatesModel.count == 0
            } 
            
            ColumnLayout{
                Layout.fillWidth: true
                spacing: Appearance.padding.small
                StyledText {
                    Layout.fillWidth: true
                    text: "Manual Search"
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.fillWidth:true
                    spacing: Appearance.padding.small
                    StyledInputField {
                        id: searchTitle
                        Layout.fillWidth: true
                        text: (Players.active?.trackTitle ?? qsTr("title")) || qsTr("title")
                        horizontalAlignment: TextInput.AlignLeft
                    }
                    StyledInputField {
                        id: searchArtist
                        Layout.fillWidth: true
                        text: (Players.active?.trackArtist ?? qsTr("artist")) || qsTr("artist")
                        horizontalAlignment: TextInput.AlignLeft
                    }
                    IconButton {
                        icon: "search"
                        onClicked: {
                            LyricsService.currentRequestId += 1
                            LyricsService.fetchNetEaseCandidates(searchTitle.text, searchArtist.text, LyricsService.currentRequestId)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing:Appearance.padding.small

                MaterialIcon {
                    text: "contrast_square"
                    font.pointSize: Appearance.font.size.large
                    color: Colours.palette.m3secondary
                }

                StyledText {
                    text: "Offset"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.normal
                }

                Item {
                    Layout.fillWidth:true
                }
                
                IconButton {
                    icon: "remove"
                    type: IconButton.Text
                    onClicked: {
                        LyricsService.offset -= 0.1;
                        LyricsService.savePrefs();
                    }
                }

                TextInput {
                    id: offsetInput
                    horizontalAlignment: TextInput.AlignHCenter
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.normal
                    selectByMouse: true
                    text: (LyricsService.offset >= 0 ? "+" : "") + LyricsService.offset.toFixed(1) + "s"

                    Binding {
                        target: offsetInput
                        property: "text"
                        value: (LyricsService.offset >= 0 ? "+" : "") + LyricsService.offset.toFixed(1) + "s"
                        when: !offsetInput.activeFocus
                    }

                    onEditingFinished: {
                        let cleaned = offsetInput.text.replace(/[+s]/g, "").trim();
                        let val = parseFloat(cleaned);
                        if (!isNaN(val)) {
                            LyricsService.offset = parseFloat(val.toFixed(1));
                            LyricsService.savePrefs();
                        } else {
                            offsetInput.text = (LyricsService.offset >= 0 ? "+" : "") + LyricsService.offset.toFixed(1) + "s";
                        }
                    }
                }
                
                IconButton {
                    icon: "add"
                    type: IconButton.Text
                    onClicked: {
                        LyricsService.offset += 0.1;
                        LyricsService.savePrefs();
                    }
                }

            }

        }
    }

    RowLayout {
        parent: LyricsService.model.count == 0 || !LyricsService.lyricsVisible ? details: leftSection
        id: playerChanger
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.small

        PlayerControl {
            type: IconButton.Text
            icon: "move_up"
            inactiveOnColour: Colours.palette.m3secondary
            padding: Appearance.padding.small
            font.pointSize: Appearance.font.size.large
            disabled: !Players.active?.canRaise
            onClicked: {
                Players.active?.raise();
                root.visibilities.dashboard = false;
            }
        }

        SplitButton {
            id: playerSelector

            disabled: !Players.list.length
            active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0] ?? null
            menu.onItemSelected: item => Players.manualActive = (item as PlayerItem).modelData

            menuItems: playerList.instances
            fallbackIcon: "music_off"
            fallbackText: qsTr("No players")

            label.Layout.maximumWidth: slider.implicitWidth * 0.28
            label.elide: Text.ElideRight

            stateLayer.disabled: true
            menuOnTop: true

            Variants {
                id: playerList

                model: Players.list

                PlayerItem {}
            }
        }

        PlayerControl {
            type: IconButton.Text
            icon: "delete"
            inactiveOnColour: Colours.palette.m3error
            padding: Appearance.padding.small
            font.pointSize: Appearance.font.size.large
            disabled: !Players.active?.canQuit
            onClicked: Players.active?.quit()
        }
    }

    component PlayerItem: MenuItem {
        required property MprisPlayer modelData

        icon: modelData === Players.active ? "check" : ""
        text: Players.getIdentity(modelData)
        activeIcon: "animated_images"
    }

    component PlayerControl: IconButton {
        Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Appearance.padding.large : internalChecked ? Appearance.padding.smaller : 0)
        radius: stateLayer.pressed ? Appearance.rounding.small / 2 : internalChecked ? Appearance.rounding.small : implicitHeight / 2
        radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
        radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }
}
