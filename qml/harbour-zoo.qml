import QtQuick 2.6
import Sailfish.Silica 1.0
import "pages"
import "cover"

ApplicationWindow {
    id: app

    // Brand palette (from icons/harbour-zoo.svg). Chrome/text use Theme.*; these carry the
    // personality on specimen/zoo surfaces and playful accents only. See docs/ui-ux-system.md.
    readonly property color zooInk:    "#282C3D"
    readonly property color zooCream:  "#F6EFDD"
    readonly property color zooPupil:  "#1A1C26"
    readonly property color zooField1: "#F2C85C"
    readonly property color zooField2: "#E1A42C"
    readonly property color zooTeal:   "#2A9D8F"

    initialPage: Component { ZooPage { } }
    cover: Component { CoverPage { } }
    allowedOrientations: defaultAllowedOrientations

    function _fmt(s) { var m = Math.floor(s / 60), r = s % 60; return m + ":" + (r < 10 ? "0" + r : r) }

    // Persistent focus banner — shown on every page while a Pomodoro session runs. Tap to open
    // Today (where you can give up). Sits at the bottom to avoid page headers.
    Rectangle {
        id: focusBanner
        z: 10000
        visible: Zoo.focusRunning
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Theme.itemSizeExtraSmall
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.96)

        Row {
            anchors.centerIn: parent
            spacing: Theme.paddingMedium
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "⏳ " + app._fmt(Zoo.focusRemaining)
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("focusing")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: pageStack.push(Qt.resolvedUrl("pages/TodayPage.qml"))
        }
    }
}
