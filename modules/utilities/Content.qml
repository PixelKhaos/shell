import "cards"
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities.cards as UtilCards

Item {
    id: root

    required property var props
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Appearance.spacing.normal


        UtilCards.HyprSunset {}

        UtilCards.IdleInhibit {}

        // Combined media card: Screenshots + Recordings in tabs
        UtilCards.Media {
            props: root.props
            visibilities: root.visibilities
            z: 1
        }

        UtilCards.Toggles {
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }

    RecordingDeleteModal {
        props: root.props
    }

    ScreenshotDeleteModal {
        props: root.props
        visible: Config.utilities.showScreenshots
    }
}
