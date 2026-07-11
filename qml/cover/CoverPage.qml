import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// Cover: a live blob, the current habit + its progress, and two actions — cycle to the next
// habit, and validate (check in) the one shown.
CoverBackground {
    id: cover

    property var habits: Zoo.habits
    property int idx: 0
    function cur() { return (habits.length > 0 && idx < habits.length) ? habits[idx] : null }

    BlobSpecimen {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.paddingMedium }
        width: parent.width * 0.42; height: width
        seed: 424242
        styleOverride: Zoo.blobStyle
        lodLevel: 1
    }

    Column {
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            margins: Theme.paddingMedium; bottomMargin: Theme.paddingLarge
        }
        spacing: Theme.paddingSmall

        Label {
            width: parent.width
            text: cover.cur() ? cover.cur().name : qsTr("No habits yet")
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            truncationMode: TruncationMode.Fade
        }
        Label {
            width: parent.width
            visible: cover.cur() !== null
            text: {
                var h = cover.cur()
                if (!h) return ""
                if (h.target > 1) return h.doneCount + " / " + h.target + qsTr(" today")
                return h.doneToday ? qsTr("done today") : qsTr("to do")
            }
            color: (cover.cur() && cover.cur().doneToday) ? Theme.secondaryColor : Theme.highlightColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: cover.idx = cover.habits.length > 0 ? (cover.idx + 1) % cover.habits.length : 0
        }
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: if (cover.cur()) Zoo.logHabit(cover.cur().id)
        }
    }
}
