import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

CoverBackground {
    // A live blob peeks from the cover — the reward, always a little alive. (Cover uses a fixed
    // seed so it's stable; the real cover will show the liveliest enclosure — see docs/zoo-meta.md.)
    BlobSpecimen {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Theme.paddingLarge
        width: parent.width * 0.62
        height: width
        seed: 424242
        lodLevel: 1
    }

    Label {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        text: qsTr("Zoo")
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeLarge
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
        }
    }
}
