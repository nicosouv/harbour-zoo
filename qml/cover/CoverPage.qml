import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// Cover: a live blob, then either the running Pomodoro countdown or the current habit + progress.
// Two actions: cycle to the next habit, and validate (check in) the one shown.
CoverBackground {
    id: cover

    property var habits: Zoo.habits
    property int idx: 0
    function cur() { return (habits.length > 0 && idx < habits.length) ? habits[idx] : null }
    function mmss(s) { var m = Math.floor(s / 60), r = s % 60; return m + ":" + (r < 10 ? "0" + r : r) }

    BlobSpecimen {
        id: coverBlob
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.paddingLarge }
        width: parent.width * 0.4; height: width
        seed: 424242
        styleOverride: Zoo.blobStyle
        lodLevel: 1
    }

    // Content sits between the blob and the action bar, so nothing overlaps.
    Column {
        anchors {
            top: coverBlob.bottom; topMargin: Theme.paddingMedium
            left: parent.left; right: parent.right; margins: Theme.paddingMedium
        }
        spacing: Theme.paddingSmall

        // Pomodoro (when running) takes priority.
        Label {
            width: parent.width; horizontalAlignment: Text.AlignHCenter
            visible: Zoo.focusRunning
            text: "⏳ " + cover.mmss(Zoo.focusRemaining)
            color: Theme.highlightColor; font.pixelSize: Theme.fontSizeLarge
        }
        Label {
            width: parent.width; horizontalAlignment: Text.AlignHCenter
            visible: Zoo.focusRunning
            text: qsTr("focusing")
            color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
        }

        // Otherwise, the current habit.
        Label {
            width: parent.width
            visible: !Zoo.focusRunning
            text: cover.cur() ? cover.cur().name : qsTr("No habits yet")
            color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall
            truncationMode: TruncationMode.Fade
        }
        Label {
            width: parent.width
            visible: !Zoo.focusRunning && cover.cur() !== null
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
