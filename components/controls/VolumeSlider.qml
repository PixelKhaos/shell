import "../"
import "../effects"
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Slider {
    id: root
    
    property bool showIcon: true
    property bool showPercentage: false
    property bool muted: false
    property string icon: {
        if (muted) return "volume_off"
        if (value < 0.01) return "volume_mute"
        if (value < 0.33) return "volume_down"
        if (value < 0.67) return "volume_medium"
        return "volume_up"
    }
    property real oldValue: 0
    
    orientation: Qt.Horizontal
    from: 0.0
    to: 1.0
    stepSize: 0.01
    height: 24
    
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 4
        radius: 2
        color: Colours.tPalette.m3surfaceContainer
        
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            color: Colours.palette.m3secondary
            radius: parent.radius
        }
    }
    
    handle: Rectangle {
        id: handleRect
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 16
        height: 16
        radius: 8
        color: Colours.palette.m3inverseSurface
        
        Behavior on width {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
        
        Behavior on height {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }
    
    onPressedChanged: {
        if (pressed) {
            handleRect.width = 20
            handleRect.height = 20
        } else {
            handleRect.width = 16
            handleRect.height = 16
        }
    }
    
    onValueChanged: {
        if (Math.abs(value - oldValue) < 0.01)
            return;
        oldValue = value;
    }
}
