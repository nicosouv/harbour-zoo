import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// The zoo itself: your hatched blobs living in an enclosure, plus whatever objects you've unlocked.
// Hatch new blobs by spending Crumbs (earned from habits/quests/challenge — that's the link).
Page {
    id: page
    allowedOrientations: Orientation.All

    function decoEmoji(id) {
        if (id === "rock") return "🪨";
        if (id === "fern") return "🌿";
        if (id === "sign") return "🪧";
        if (id === "lamp") return "💡";
        if (id === "pond") return "🌊";
        if (id === "arch") return "🏛️";
        return "✦";
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Shop"); onClicked: pageStack.push(Qt.resolvedUrl("ShopPage.qml")) }
            MenuItem {
                text: Zoo.canHatch ? qsTr("Hatch a blob (%1 crumbs)").arg(Zoo.hatchCost)
                                   : qsTr("Hatch a blob (need %1 crumbs)").arg(Zoo.hatchCost)
                enabled: Zoo.canHatch
                onClicked: Zoo.hatchBlob()
            }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Your zoo")
                description: qsTr("%1 crumbs · %2 residents").arg(Zoo.crumbs).arg(Zoo.ownedBlobs.length)
            }

            // Decorations you've unlocked.
            Flow {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                Repeater {
                    model: Zoo.shopItems
                    delegate: Rectangle {
                        visible: modelData.owned
                        height: Theme.itemSizeExtraSmall
                        width: chip.width + Theme.paddingLarge
                        radius: height / 2
                        color: Theme.rgba(Theme.highlightBackgroundColor, 0.2)
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: Theme.paddingSmall
                            Label { text: page.decoEmoji(modelData.id); font.pixelSize: Theme.fontSizeSmall }
                            Label { text: modelData.name; color: Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeExtraSmall }
                        }
                    }
                }
            }

            // The enclosure.
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Math.max(page.height * 0.34, blobFlow.height + 2 * Theme.paddingLarge)
                radius: Theme.paddingLarge
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2E3350" }
                    GradientStop { position: 1.0; color: "#20233A" }
                }

                Label {
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.paddingLarge
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: Zoo.ownedBlobs.length === 0
                    text: qsTr("Empty. Deeply, cavernously empty. Do a habit or two, earn some "
                               + "crumbs, then hatch something. It'll help, honestly.")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }

                Flow {
                    id: blobFlow
                    anchors {
                        left: parent.left; right: parent.right; top: parent.top
                        margins: Theme.paddingLarge
                    }
                    spacing: Theme.paddingMedium
                    Repeater {
                        model: Zoo.ownedBlobs
                        delegate: BlobSpecimen {
                            width: (blobFlow.width - 2 * Theme.paddingMedium) / 3
                            height: width
                            seed: modelData.seed
                            rarity: modelData.rarity
                            voice: Zoo.playerName
                            lodLevel: 1
                            MouseArea {
                                anchors.fill: parent
                                onClicked: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"),
                                                          { seed: modelData.seed, rarity: modelData.rarity })
                            }
                        }
                    }
                }
            }

            // Hatch action, front and centre.
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Hatch a blob — %1 crumbs").arg(Zoo.hatchCost)
                enabled: Zoo.canHatch
                onClicked: Zoo.hatchBlob()
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: Zoo.canHatch
                      ? qsTr("Go on. You've earned it.")
                      : qsTr("Not enough crumbs yet. Go be productive; the blobs will wait.")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
        VerticalScrollDecorator {}
    }

    // Reveal the newcomer.
    Connections {
        target: Zoo
        onHatched: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"), { seed: seed, rarity: rarity })
    }
}
