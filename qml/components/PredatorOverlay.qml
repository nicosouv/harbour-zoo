import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// The Quest Beast: when quests go overdue, a big blob sweeps across, eats a resident (already
// removed from the model), and leaves. Dramatic, goofy, and briefly. Call run(n).
Item {
    id: root
    anchors.fill: parent
    property int count: 0
    visible: count > 0

    function run(n) {
        if (n <= 0) return
        root.count = n
        predator.x = -predator.width
        sweep.restart()
    }

    Rectangle { id: dim; anchors.fill: parent; color: "#000000"; opacity: 0 }

    BlobSpecimen {
        id: predator
        width: parent.width * 0.5; height: width
        y: parent.height * 0.36
        seed: 66613
        styleOverride: "chonk"
        voice: qsTr("NOM")
        lodLevel: 0
    }

    Label {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.paddingLarge * 2 }
        width: parent.width - 2 * Theme.horizontalPageMargin
        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
        visible: root.count > 0
        text: qsTr("The Quest Beast ate %1. Overdue quests have consequences. Mild ones.").arg(
                  root.count === 1 ? qsTr("a blob") : qsTr("%1 blobs").arg(root.count))
        color: "#F6EFDD"; font.pixelSize: Theme.fontSizeSmall
    }

    SequentialAnimation {
        id: sweep
        NumberAnimation { target: dim; property: "opacity"; to: 0.5; duration: 300 }
        NumberAnimation {
            target: predator; property: "x"
            to: root.width * 0.5 - predator.width / 2; duration: 800; easing.type: Easing.OutQuad
        }
        ScriptAction { script: predator.react() }   // a big chomp + "NOM"
        PauseAnimation { duration: 900 }
        NumberAnimation { target: predator; property: "x"; to: root.width; duration: 700; easing.type: Easing.InQuad }
        NumberAnimation { target: dim; property: "opacity"; to: 0; duration: 300 }
        ScriptAction { script: root.count = 0 }
    }
}
