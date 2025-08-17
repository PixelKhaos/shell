pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var lock
    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Config.lock.sizes.centerWidth * centerScale

    Layout.preferredWidth: centerWidth
    Layout.fillHeight: true

    spacing: Appearance.spacing.large * 2

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeComponents[0]
            color: Colours.palette.m3secondary
            font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
            font.family: Appearance.font.family.clock
            font.bold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: ":"
            color: Colours.palette.m3primary
            font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
            font.family: Appearance.font.family.clock
            font.bold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeComponents[1]
            color: Colours.palette.m3secondary
            font.pointSize: Math.floor(Appearance.font.size.extraLarge * 3 * root.centerScale)
            font.family: Appearance.font.family.clock
            font.bold: true
        }

        Loader {
            Layout.leftMargin: Appearance.spacing.small
            Layout.alignment: Qt.AlignVCenter

            asynchronous: true
            active: Config.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: root.timeComponents[2] ?? ""
                color: Colours.palette.m3primary
                font.pointSize: Math.floor(Appearance.font.size.extraLarge * 2 * root.centerScale)
                font.family: Appearance.font.family.clock
                font.bold: true
            }
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -Appearance.padding.large * 2

        text: Time.format("dddd, d MMMM yyyy")
        color: Colours.palette.m3tertiary
        font.pointSize: Math.floor(Appearance.font.size.extraLarge * root.centerScale)
        font.family: Appearance.font.family.mono
        font.bold: true
    }

    StyledClippingRect {
        Layout.topMargin: Appearance.spacing.large * 2
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: root.centerWidth / 2
        implicitHeight: root.centerWidth / 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        MaterialIcon {
            anchors.centerIn: parent

            text: "person"
            fill: 1
            grade: 200
            font.pointSize: Math.floor(root.centerWidth / 4)
        }

        CachingImage {
            id: pfp

            anchors.fill: parent
            path: `${Paths.stringify(Paths.home)}/.face`
        }
    }

    StyledRect {
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: root.centerWidth * 0.8
        implicitHeight: input.implicitHeight + Appearance.padding.small * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        focus: true
        onActiveFocusChanged: {
            if (!activeFocus)
                forceActiveFocus();
        }

        Keys.onPressed: event => {
            if (!root.lock.locked)
                return;

            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
                inputField.placeholder.animate = false;

            root.lock.pam.handleKey(event);
        }

        StateLayer {
            hoverEnabled: false
            cursorShape: Qt.IBeamCursor

            function onClicked(): void {
                parent.forceActiveFocus();
            }
        }

        RowLayout {
            id: input

            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.normal

            Item {
                implicitWidth: implicitHeight
                implicitHeight: fprintIcon.implicitHeight + Appearance.padding.small * 2

                // Active scanning indicator circle
                Rectangle {
                    anchors.centerIn: parent
                    width: fprintIcon.implicitWidth + Appearance.padding.normal
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Colours.palette.m3primary
                    opacity: (root.lock.pam.fprint.active && !root.lock.pam.fprintState) ? 0.8 : 0
                    
                    Behavior on opacity {
                        Anim {}
                    }
                    
                    // Pulse animation
                    SequentialAnimation on scale {
                        running: root.lock.pam.fprint.active && !root.lock.pam.fprintState
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 1.0
                            to: 1.1
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            from: 1.1
                            to: 1.0
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                MaterialIcon {
                    id: fprintIcon

                    anchors.centerIn: parent
                    animate: true
                    text: {
                        if (root.lock.pam.fprintState === "error")
                            return "error";
                        if (root.lock.pam.fprint.tries >= Config.lock.maxFprintTries || root.lock.pam.fprintState === "fail")
                            return "fingerprint_off";
                        if (root.lock.pam.fprint.active)
                            return "fingerprint";
                        return "lock";
                    }
                    color: root.lock.pam.fprintState ? Colours.palette.m3error : Colours.palette.m3onSurface
                    opacity: root.lock.pam.passwd.active ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }

                StyledBusyIndicator {
                    anchors.fill: parent
                    running: root.lock.pam.passwd.active
                }
            }

            InputField {
                id: inputField

                pam: root.lock.pam
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: enterIcon.implicitHeight + Appearance.padding.small * 2

                color: root.lock.pam.buffer ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                radius: Appearance.rounding.full

                StateLayer {
                    color: root.lock.pam.buffer ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    function onClicked(): void {
                        root.lock.pam.passwd.start();
                    }
                }

                MaterialIcon {
                    id: enterIcon

                    anchors.centerIn: parent
                    text: "arrow_forward"
                    color: root.lock.pam.buffer ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    font.weight: 500
                }
            }
        }
    }

    // Fingerprint feedback text
    Text {
        id: fprintFeedback
        
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Appearance.padding.small
        
        text: {
            if (root.lock.pam.fprintState === "fail")
                return `Fingerprint not recognized (${root.lock.pam.fprint.tries}/${Config.lock.maxFprintTries}). Try again or use password.`;
            if (root.lock.pam.fprintState === "max")
                return `Too many failed attempts (${Config.lock.maxFprintTries}/${Config.lock.maxFprintTries}). Please use password.`;
            if (root.lock.pam.fprintState === "error")
                return "Fingerprint scanner error. Please use password.";
            return `Fingerprint not recognized (${root.lock.pam.fprint.tries}/${Config.lock.maxFprintTries}). Try again or use password.`; // Placeholder to maintain layout
        }
        color: Colours.palette.m3error
        font.pixelSize: Appearance.text.sizes.small
        opacity: root.lock.pam.fprintState ? 1 : 0
        
        Behavior on opacity {
            Anim {}
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
