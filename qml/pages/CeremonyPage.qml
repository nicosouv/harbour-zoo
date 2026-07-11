import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"
import "../components"

// A celebratory moment: farewell (a blob leaving for new adventures), a habit milestone, a
// birthday, a national holiday. Shown one at a time; Continue chains to the next pending one.
Page {
    id: page
    allowedOrientations: Orientation.All
    backNavigation: false

    property var ceremony: ({})

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ceremony.emoji ? ceremony.emoji : "🎉"
                font.pixelSize: Theme.fontSizeHuge * 2
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ceremony.title ? ceremony.title : ""
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }

            BlobSpecimen {
                anchors.horizontalCenter: parent.horizontalCenter
                width: page.width * 0.32; height: width
                seed: ceremony.seed !== undefined ? ceremony.seed : 20260714
                styleOverride: Zoo.blobStyle
                voice: Zoo.playerName
                lodLevel: 0
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: ceremony.body ? ceremony.body : ""
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Continue")
                onClicked: {
                    Zoo.dismissCeremony(ceremony.id)
                    var next = Zoo.pendingCeremonies()
                    if (next.length > 0)
                        pageStack.replace(Qt.resolvedUrl("CeremonyPage.qml"), { ceremony: next[0] })
                    else
                        pageStack.pop()
                }
            }
        }
    }

    ConfettiBurst { id: confetti }
    Timer {
        interval: 250; running: true; repeat: false
        onTriggered: confetti.fireAt(page.width / 2, page.height * 0.4)
    }
}
