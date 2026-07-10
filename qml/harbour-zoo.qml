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

    initialPage: Component { TodayPage { } }
    cover: Component { CoverPage { } }
    allowedOrientations: defaultAllowedOrientations
}
