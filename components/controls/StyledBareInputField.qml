// StyledBareInputField.qml
pragma ComponentBehavior: Bound
import ".."
import qs.services
import qs.config
import QtQuick

Item {
    id: root
    property string text: ""
    property int horizontalAlignment: TextInput.AlignHCenter
    signal editingFinished

    implicitWidth: 70
    implicitHeight: inputField.implicitHeight + Appearance.padding.small * 2

    StyledRect {
        id: container
        anchors.fill: parent
        color: inputHover.containsMouse || inputField.activeFocus
            ? Colours.layer(Colours.palette.m3surfaceContainer, 3)
            : Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Appearance.rounding.small
        border.width: 1
        border.color: inputField.activeFocus
            ? Colours.palette.m3primary
            : Qt.alpha(Colours.palette.m3outline, 0.3)

        Behavior on color { CAnim {} }
        Behavior on border.color { CAnim {} }

        MouseArea {
            id: inputHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
            acceptedButtons: Qt.NoButton
        }

        TextInput {
            id: inputField
            anchors.centerIn: parent
            width: parent.width - Appearance.padding.normal
            horizontalAlignment: root.horizontalAlignment
            color: Colours.palette.m3onSurface
            font.family: Appearance.font.family.sans
            font.pointSize: Appearance.font.size.smaller
            renderType: TextInput.NativeRendering
            selectByMouse: true

            Component.onCompleted: text = root.text

            Binding {
                target: inputField
                property: "text"
                value: root.text
                when: !inputField.activeFocus
            }

            onTextChanged: root.text = text
            onEditingFinished: root.editingFinished()
        }
    }
}
