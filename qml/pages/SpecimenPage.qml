import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// Full-screen specimen host. Demonstrates a single blob big, with its (sample) name/lore/rarity,
// and a reroll to show off that no two blobs are alike. Real flavor/persistence wire in later.
Page {
    id: page
    allowedOrientations: Orientation.All

    property int seed: 1

    // Rarity is rolled here for the demo; normally it comes from the seeded hatch roll.
    property var rarities: ["common", "uncommon", "rare", "mythic"]
    property string rarity: rarities[Math.abs(seed) % 4 === 0
                                     ? (Math.abs(seed) % 40 === 0 ? 3 : 2)
                                     : (Math.abs(seed) % 2)]

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem { text: qsTr("Meet another"); onClicked: page.seed = Zoo.newSeed() }
        }

        Column {
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: blob.displayName }

            BlobSpecimen {
                id: blob
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(page.width, page.height) * 0.72
                height: width
                seed: page.seed
                rarity: page.rarity
                lodLevel: 0
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: blob.lore
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.rarity.toUpperCase()
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                font.letterSpacing: 2
            }
        }
    }
}
