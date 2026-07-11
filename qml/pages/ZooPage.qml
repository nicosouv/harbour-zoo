import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"
import "../components"

// HOME. The zoo is the star: small blobs roam slowly across a pixel-art biome you can theme and
// decorate. A quiet reflection line hints, slowly, at what the whole thing is really about.
Page {
    id: page
    allowedOrientations: Orientation.All

    function decoEmoji(id) {
        if (id === "rock") return "🪨"; if (id === "fern") return "🌿"; if (id === "sign") return "🪧";
        if (id === "lamp") return "💡"; if (id === "pond") return "🌊"; if (id === "arch") return "🏛️";
        if (id === "statue") return "🗿"; if (id === "balloon") return "🎈"; if (id === "gnome") return "🧙";
        if (id === "swing") return "🛝"; if (id === "totem") return "🪅"; if (id === "fountain") return "⛲";
        return "✦";
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Settings"); onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml")) }
            MenuItem { text: qsTr("Shop"); onClicked: pageStack.push(Qt.resolvedUrl("ShopPage.qml")) }
            MenuItem { text: qsTr("Keeper"); onClicked: pageStack.push(Qt.resolvedUrl("KeeperPage.qml")) }
            MenuItem { text: qsTr("Today"); onClicked: pageStack.push(Qt.resolvedUrl("TodayPage.qml")) }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Your zoo")
                description: qsTr("%1 · level %2").arg(Zoo.keeperTitle).arg(Zoo.keeperLevel)
            }

            Column {
                width: parent.width; spacing: Theme.paddingMedium
                visible: !Zoo.onboarded
                Label {
                    x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    text: qsTr("A zoo. Empty, judgemental. Do useful things under 'Today' → earn crumbs → hatch odd little creatures here.")
                    color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall
                }
                TextField {
                    id: nameField; width: parent.width
                    label: qsTr("Name? (optional)"); placeholderText: qsTr("So they can shout it")
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"; EnterKey.onClicked: focus = false
                }
                Button { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Go")
                    onClicked: { if (nameField.text.trim().length > 0) Zoo.playerName = nameField.text.trim(); Zoo.onboarded = true } }
            }

            Row {
                x: Theme.horizontalPageMargin; spacing: Theme.paddingLarge
                Label { text: "🍞 " + Zoo.crumbs; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                Label { text: "🥚 " + Zoo.ownedBlobs.length; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                Label { text: "🔥 " + Zoo.streak; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
            }

            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap; text: Zoo.statusPhrase
                color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeSmall
            }

            // Biome picker.
            Flow {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                Repeater {
                    model: Zoo.themes
                    delegate: BackgroundItem {
                        width: swatch.width + Theme.paddingMedium; height: Theme.itemSizeExtraSmall
                        onClicked: modelData.owned ? Zoo.selectTheme(modelData.id)
                                                   : pageStack.push(Qt.resolvedUrl("ShopPage.qml"))
                        Rectangle {
                            anchors.fill: parent; radius: height / 2
                            color: modelData.selected ? Theme.rgba(Theme.highlightColor, 0.3)
                                                       : Theme.rgba(Theme.highlightBackgroundColor, 0.12)
                        }
                        Label {
                            id: swatch; anchors.centerIn: parent
                            text: modelData.owned ? modelData.name : (modelData.name + " · " + modelData.cost + "🍞")
                            color: modelData.owned ? Theme.primaryColor : Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeTiny
                        }
                    }
                }
            }

            // The enclosure: a pixel-art biome where small blobs roam slowly.
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: page.height * 0.46
                radius: Theme.paddingLarge
                clip: true
                color: "#000000"

                BiomeBackground { id: biome; anchors.fill: parent; theme: Zoo.selectedTheme }

                Label {
                    anchors.centerIn: parent; width: parent.width - 2 * Theme.paddingLarge
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                    visible: Zoo.ownedBlobs.length === 0
                    text: qsTr("Empty. Do a habit, earn crumbs, hatch something. It helps.")
                    color: "#F6EFDD"; font.pixelSize: Theme.fontSizeSmall
                }

                Repeater {
                    model: Zoo.ownedBlobs
                    delegate: Item {
                        id: roamer
                        property real blobSize: biome.width / 7
                        property int  dur: 4000
                        width: blobSize; height: blobSize
                        function rx() { return Math.random() * (biome.width - blobSize) }
                        function ry() { return biome.height * 0.34 + Math.random() * (biome.height * 0.60 - blobSize) }
                        Component.onCompleted: { x = rx(); y = ry() }
                        Behavior on x { NumberAnimation { duration: roamer.dur; easing.type: Easing.InOutSine } }
                        Behavior on y { NumberAnimation { duration: roamer.dur; easing.type: Easing.InOutSine } }
                        Timer {
                            interval: 2600 + Math.random() * 4000; running: true; repeat: true
                            onTriggered: { roamer.dur = 4000 + Math.random() * 5000; roamer.x = roamer.rx(); roamer.y = roamer.ry() }
                        }
                        BlobSpecimen {
                            anchors.fill: parent
                            seed: modelData.seed; rarity: modelData.rarity
                            voice: Zoo.playerName; lodLevel: 1
                            MouseArea {
                                anchors.fill: parent
                                onClicked: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"),
                                                          { seed: modelData.seed, rarity: modelData.rarity, date: modelData.date })
                            }
                        }
                    }
                }
            }

            // The quiet part. Small, secondary, easy to skim past — until one day it isn't.
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                visible: Zoo.reflection.length > 0
                wrapMode: Text.Wrap; text: Zoo.reflection
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
                font.italic: true
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Hatch a blob (%1 🍞)").arg(Zoo.hatchCost)
                enabled: Zoo.canHatch; onClicked: Zoo.hatchBlob()
            }

            // Owned decorations.
            Flow {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                Repeater {
                    model: Zoo.shopItems
                    delegate: Label {
                        visible: modelData.owned
                        text: page.decoEmoji(modelData.id) + " " + modelData.name
                        color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeTiny
                    }
                }
            }

            // Fun fact of the day.
            Rectangle {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                height: factCol.height + 2 * Theme.paddingMedium
                radius: Theme.paddingMedium; color: Theme.rgba(Theme.highlightBackgroundColor, 0.12)
                Column {
                    id: factCol; anchors.verticalCenter: parent.verticalCenter
                    x: Theme.paddingLarge; width: parent.width - 2 * Theme.paddingLarge; spacing: Theme.paddingSmall
                    Label { text: qsTr("Fun fact, allegedly"); color: Theme.highlightColor; font.pixelSize: Theme.fontSizeExtraSmall }
                    Label { width: parent.width; wrapMode: Text.Wrap; text: Zoo.funFact; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                }
            }
        }
        VerticalScrollDecorator {}
    }

    Connections {
        target: Zoo
        onHatched: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"), { seed: seed, rarity: rarity })
    }
}
