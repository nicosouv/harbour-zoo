import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// Full-screen view of a single blob, with its name/lore/rarity. Rarity may be passed in (for an
// owned/just-hatched blob); otherwise it's derived from the seed for a casual preview.
Page {
    id: page
    allowedOrientations: Orientation.All

    property int seed: 1
    property string rarity: ""
    property string date: ""

    readonly property var _rarities: ["common", "uncommon", "rare", "mythic"]
    readonly property string shownRarity: rarity.length > 0
        ? rarity
        : _rarities[Math.abs(seed) % 4 === 0
                    ? (Math.abs(seed) % 40 === 0 ? 3 : 2)
                    : (Math.abs(seed) % 2)]

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem { text: qsTr("Meet another"); onClicked: page.seed = Zoo.newSeed(); }
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
                rarity: page.shownRarity
                voice: Zoo.playerName
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
                text: page.shownRarity.toUpperCase()
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                font.letterSpacing: 2
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: page.date.length > 0
                text: qsTr("moved in on %1, a day you showed up").arg(page.date)
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeTiny
            }
        }
    }
}
