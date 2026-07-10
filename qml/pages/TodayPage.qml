import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// The home page. Utility-first: the useful trackers own the body; the zoo/status live in the
// frame. This is a scaffold — habits/focus/challenge are wired to real services later. See
// docs/ui-ux-system.md for the target layout and budget (~60% tracking / 25% reward / 15% status).
Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Meet a blob"); onClicked: openBlob(Zoo.newSeed()) }
            MenuItem { text: qsTr("About"); enabled: false }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Zoo")
                description: qsTr("a small, strange, living zoo")
            }

            // --- Today's challenge (sample copy until ChallengeService lands) ------------------
            SectionHeader { text: qsTr("Today") }

            BackgroundItem {
                width: parent.width
                height: challengeCol.height + 2 * Theme.paddingLarge
                Rectangle {
                    anchors {
                        fill: parent
                        leftMargin: Theme.horizontalPageMargin
                        rightMargin: Theme.horizontalPageMargin
                    }
                    radius: Theme.paddingMedium
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.15)
                }
                Column {
                    id: challengeCol
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin + Theme.paddingLarge
                    width: parent.width - 2 * (Theme.horizontalPageMargin + Theme.paddingLarge)
                    spacing: Theme.paddingSmall
                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("Introduce yourself to a cloud. Keep it professional.")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    Label {
                        text: qsTr("Do it, then come back — a little thing worth doing.")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            // --- Reward peek: prove the blobs are fun and non-identical ------------------------
            SectionHeader { text: qsTr("Your zoo") }

            Item {
                width: parent.width
                height: page.width * 0.5

                BlobSpecimen {
                    id: peek
                    anchors.centerIn: parent
                    width: page.width * 0.42
                    height: width
                    seed: 1
                    lodLevel: 0
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: openBlob(peek.seed)
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Meet another")
                onClicked: peek.seed = Zoo.newSeed()
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Habits and focus move in next. For now: tap a blob, and pull down to meet more. No two are the same.")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
        VerticalScrollDecorator {}
    }

    function openBlob(seed) {
        pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"), { seed: seed })
    }
}
