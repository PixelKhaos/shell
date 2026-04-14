pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.components
import qs.services
import qs.config
import ".."

Item {
    id: root

    required property NexusSession session

    readonly property bool collapsed: session.sidebarCollapsed

    property bool searchDropdownOpen: false
    property bool configDropdownOpen: false

    // Build config model: Global + monitors
    readonly property var configModel: {
        const items = [
            {
                id: "global",
                label: "Global",
                icon: "language",
                desc: "Settings apply everywhere"
            }
        ];
        for (const screen of Screens.screens) {
            items.push({
                id: screen.name,
                label: screen.name,
                icon: "monitor",
                desc: "Monitor-specific overrides"
            });
        }
        return items;
    }

    implicitHeight: headerLayout.implicitHeight

    ColumnLayout {
        id: headerLayout

        anchors.fill: parent
        spacing: 0

        // Search bar
        Item {
            id: searchItem

            Layout.fillWidth: true
            Layout.preferredHeight: root.collapsed ? 64 : 44

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            StyledRect {
                id: searchBtn

                anchors.fill: parent

                radius: root.collapsed ? Appearance.rounding.normal : Appearance.rounding.full
                color: {
                    if (root.session.searchPopoutOpen && root.collapsed)
                        return Qt.alpha(Colours.palette.m3secondaryContainer, 0.16);
                    if (!root.collapsed)
                        return Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.6);
                    return "transparent";
                }

                Behavior on radius {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
                Behavior on color {
                    CAnim {}
                }

                // Collapsed mode: click to open popout
                StateLayer {
                    function onClicked() {
                        root.session.searchPopoutOpen = !root.session.searchPopoutOpen;
                        root.session.configPopoutOpen = false;
                    }

                    visible: root.collapsed
                    radius: parent.radius
                    color: Colours.palette.m3onSurface
                }

                MaterialIcon {
                    id: searchIcon

                    x: root.collapsed ? (parent.width - width) / 2 : Appearance.padding.large
                    y: root.collapsed ? (parent.height - height) / 2 - 8 : (parent.height - height) / 2

                    text: "search"
                    font.pointSize: root.collapsed ? Appearance.font.size.large : Appearance.font.size.larger
                    color: {
                        if (root.session.searchPopoutOpen && root.collapsed)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, root.collapsed ? 0.5 : 0.4);
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on font.pointSize {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }

                // Collapsed label
                StyledText {
                    visible: root.collapsed
                    x: (parent.width - width) / 2
                    y: parent.height - height - 6

                    text: "Search"
                    font.pointSize: Appearance.font.size.small - 1
                    color: {
                        if (root.session.searchPopoutOpen && root.collapsed)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, 0.7);
                    }

                    opacity: root.collapsed ? 0.8 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }

                // Expanded mode: text input
                TextField {
                    id: searchField

                    visible: !root.collapsed
                    anchors.left: searchIcon.right
                    anchors.leftMargin: Appearance.spacing.normal
                    anchors.right: parent.right
                    anchors.rightMargin: searchClear.visible ? searchClear.width + Appearance.spacing.normal : Appearance.padding.large
                    anchors.verticalCenter: parent.verticalCenter

                    placeholderText: "Search settings..."
                    font.pointSize: Appearance.font.size.normal
                    color: Colours.palette.m3onSurface
                    placeholderTextColor: Qt.alpha(Colours.palette.m3onSurface, 0.3)
                    background: Item {}

                    onTextChanged: {
                        root.session.searchQuery = text;
                        root.searchDropdownOpen = text.length > 0;
                    }
                    onActiveFocusChanged: {
                        if (activeFocus && text.length > 0)
                            root.searchDropdownOpen = true;
                        else if (!activeFocus)
                            root.searchDropdownOpen = false;
                    }

                    Connections {
                        function onSidebarCollapsedChanged() {
                            if (root.session.sidebarCollapsed) {
                                searchField.focus = false;
                                root.searchDropdownOpen = false;
                            }
                        }

                        target: root.session
                    }
                }

                // Clear button (expanded)
                MaterialIcon {
                    id: searchClear

                    visible: !root.collapsed && root.session.searchQuery.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.padding.normal
                    anchors.verticalCenter: parent.verticalCenter

                    text: "close"
                    font.pointSize: Appearance.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.5)

                    StateLayer {
                        function onClicked() {
                            searchField.text = "";
                            root.session.searchQuery = "";
                            root.searchDropdownOpen = false;
                        }

                        radius: Appearance.rounding.full
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }

        Item {
            id: configItem

            Layout.fillWidth: true
            Layout.preferredHeight: root.collapsed ? 64 : 40
            Layout.topMargin: root.collapsed ? 4 : 8

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            StyledRect {
                id: configBtn

                anchors.fill: parent
                radius: root.collapsed ? Appearance.rounding.normal : Appearance.rounding.full
                color: {
                    if (root.session.configPopoutOpen && root.collapsed)
                        return Qt.alpha(Colours.palette.m3secondaryContainer, 0.16);
                    if (root.configDropdownOpen && !root.collapsed)
                        return Qt.alpha(Colours.palette.m3secondaryContainer, 0.12);
                    if (!root.collapsed)
                        return Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.6);
                    return "transparent";
                }

                Behavior on radius {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
                Behavior on color {
                    CAnim {}
                }

                StateLayer {
                    function onClicked() {
                        if (root.collapsed) {
                            root.session.configPopoutOpen = !root.session.configPopoutOpen;
                            root.session.searchPopoutOpen = false;
                        } else {
                            root.configDropdownOpen = !root.configDropdownOpen;
                            root.searchDropdownOpen = false;
                        }
                    }

                    radius: parent.radius
                    color: Colours.palette.m3onSurface
                }

                MaterialIcon {
                    id: configIcon

                    x: root.collapsed ? (parent.width - width) / 2 : Appearance.padding.large
                    y: root.collapsed ? (parent.height - height) / 2 - 8 : (parent.height - height) / 2

                    text: root.session.activeConfig === "global" ? "language" : "monitor"
                    font.pointSize: root.collapsed ? Appearance.font.size.large : Appearance.font.size.larger
                    color: {
                        if (root.session.configPopoutOpen && root.collapsed)
                            return Colours.palette.m3primary;
                        if (root.configDropdownOpen && !root.collapsed)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, 0.5);
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on font.pointSize {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }

                // Collapsed label
                StyledText {
                    visible: root.collapsed
                    x: (parent.width - width) / 2
                    y: parent.height - height - 6

                    text: root.session.activeConfig === "global" ? "Global" : root.session.activeConfig
                    font.pointSize: Appearance.font.size.small - 1
                    font.weight: Font.Medium
                    color: {
                        if (root.session.configPopoutOpen && root.collapsed)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, 0.7);
                    }

                    opacity: root.collapsed ? 0.8 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.anim.durations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }

                // Expanded label
                StyledText {
                    visible: !root.collapsed
                    anchors.left: configIcon.right
                    anchors.leftMargin: Appearance.spacing.normal
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.session.activeConfig === "global" ? "Global" : root.session.activeConfig
                    font.pointSize: Appearance.font.size.normal
                    font.weight: Font.Medium
                    color: {
                        if (root.configDropdownOpen)
                            return Colours.palette.m3primary;
                        return Qt.alpha(Colours.palette.m3onSurface, 0.6);
                    }

                    Behavior on color {
                        CAnim {}
                    }
                }

                MaterialIcon {
                    id: configChevron

                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.padding.large
                    anchors.verticalCenter: parent.verticalCenter

                    text: "expand_more"
                    font.pointSize: Appearance.font.size.normal
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.4)
                    rotation: (root.session.configPopoutOpen && root.collapsed) || (root.configDropdownOpen && !root.collapsed) ? 180 : 0
                    opacity: root.collapsed ? 0 : 1

                    Behavior on rotation {
                        NumberAnimation {
                            duration: Appearance.anim.durations.small
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
                        }
                    }
                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: Appearance.padding.normal
            Layout.rightMargin: Appearance.padding.normal
            Layout.topMargin: root.collapsed ? 8 : Appearance.spacing.normal
            color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
        }
    }

    // Search results dropdown (expanded)
    Rectangle {
        id: searchDropdown

        z: 10
        x: 0
        y: searchItem.y + searchItem.height + 4
        width: root.width
        height: root.searchDropdownOpen && !root.collapsed ? searchResultsCol.implicitHeight + Appearance.padding.normal * 2 : 0
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainerHigh
        clip: true
        visible: height > 0

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }

        Column {
            id: searchResultsCol

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: 2

            Repeater {
                model: root.session.searchQuery.length > 0 ? NexusRegistry.searchSettings(root.session.searchQuery) : [] // qmllint disable missing-property

                delegate: Item {
                    id: searchResultDelegate

                    required property var modelData

                    width: searchResultsCol.width
                    height: 44

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacing.normal
                        anchors.rightMargin: Appearance.spacing.normal
                        spacing: Appearance.spacing.normal

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 5
                            color: Qt.alpha(Colours.palette.m3primary, 0.1)

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "arrow_forward"
                                font.pointSize: Appearance.font.size.small - 1
                                color: Colours.palette.m3primary
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - parent.spacing - 32

                            StyledText {
                                text: searchResultDelegate.modelData.label
                                font.pointSize: Appearance.font.size.normal
                                font.weight: Font.Medium
                                color: Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: searchResultDelegate.modelData.categoryLabel + (searchResultDelegate.modelData.tab ? " › " + searchResultDelegate.modelData.tab : "")
                                font.pointSize: Appearance.font.size.small - 1
                                color: Qt.alpha(Colours.palette.m3onSurface, 0.4)
                            }
                        }
                    }

                    StateLayer {
                        function onClicked() {
                            searchField.text = "";
                            root.session.searchQuery = "";
                            root.session.setSearchNavigate(searchResultDelegate.modelData.categoryId, searchResultDelegate.modelData.tab || "");
                            root.searchDropdownOpen = false;
                        }

                        radius: Appearance.rounding.small
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }
    }

    // Config dropdown (expanded)
    Rectangle {
        id: configDropdown

        z: 10
        x: 0
        y: configItem.y + configItem.height + 4
        width: root.width
        height: root.configDropdownOpen && !root.collapsed ? configDropdownCol.implicitHeight + Appearance.padding.normal * 2 : 0
        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainerHigh
        clip: true
        visible: height > 0

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.34, 1.56, 0.64, 1, 1, 1]
            }
        }

        Column {
            id: configDropdownCol

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: 2

            Repeater {
                model: root.configModel

                delegate: Item {
                    id: configDropdownDelegate

                    required property var modelData
                    readonly property bool isActive: root.session.activeConfig === modelData.id

                    width: configDropdownCol.width
                    height: 44

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacing.normal
                        anchors.rightMargin: Appearance.spacing.normal
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: configDropdownDelegate.modelData.icon
                            font.pointSize: Appearance.font.size.normal
                            color: configDropdownDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - parent.spacing - 24

                            StyledText {
                                text: configDropdownDelegate.modelData.label
                                font.pointSize: Appearance.font.size.normal
                                font.weight: Font.Medium
                                color: configDropdownDelegate.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            }
                            StyledText {
                                text: configDropdownDelegate.modelData.desc
                                font.pointSize: Appearance.font.size.small - 1
                                color: Qt.alpha(Colours.palette.m3onSurface, 0.4)
                            }
                        }
                    }

                    StateLayer {
                        function onClicked() {
                            root.session.activeConfig = configDropdownDelegate.modelData.id;
                            root.configDropdownOpen = false;
                        }

                        radius: Appearance.rounding.small
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }
    }
}
