import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// HOME. The zoo is the star: your hatched blobs living in an enclosure, plus a fun fact and a
// (mildly insulting) status line. The useful loop lives one pull-down away, under "Today".
Page {
    id: page
    allowedOrientations: Orientation.All

    function decoEmoji(id) {
        if (id === "rock") return "🪨"; if (id === "fern") return "🌿"; if (id === "sign") return "🪧";
        if (id === "lamp") return "💡"; if (id === "pond") return "🌊"; if (id === "arch") return "🏛️";
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

            // First-run intro (home is the zoo now).
            Column {
                width: parent.width; spacing: Theme.paddingMedium
                visible: !Zoo.onboarded
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    text: qsTr("A zoo. Empty, judgemental. Do useful things under 'Today' → earn crumbs → hatch odd little creatures here.")
                    color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall
                }
                TextField {
                    id: nameField; width: parent.width
                    label: qsTr("Name? (optional)"); placeholderText: qsTr("So they can shout it")
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"; EnterKey.onClicked: focus = false
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Go")
                    onClicked: {
                        if (nameField.text.trim().length > 0) Zoo.playerName = nameField.text.trim()
                        Zoo.onboarded = true
                    }
                }
            }

            // Status at a glance.
            Row {
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingLarge
                Label { text: "🍞 " + Zoo.crumbs; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                Label { text: "🥚 " + Zoo.ownedBlobs.length; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                Label { text: "🔥 " + Zoo.streak; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
            }

            // Adaptive, faintly rude status line.
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap; text: Zoo.statusPhrase
                color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeSmall
            }

            // Owned decorations.
            Flow {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
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

            // The enclosure (hero). Blobs are small; you can fit a crowd.
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Math.max(page.height * 0.40, blobFlow.height + 2 * Theme.paddingLarge)
                radius: Theme.paddingLarge
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#3B3F52" }
                    GradientStop { position: 1.0; color: "#22242F" }
                }
                Label {
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.paddingLarge
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                    visible: Zoo.ownedBlobs.length === 0
                    text: qsTr("Empty. Do a habit, earn crumbs, hatch something. It helps.")
                    color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeSmall
                }
                Flow {
                    id: blobFlow
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.paddingLarge }
                    spacing: Theme.paddingMedium
                    Repeater {
                        model: Zoo.ownedBlobs
                        delegate: BlobSpecimen {
                            width: (blobFlow.width - 3 * Theme.paddingMedium) / 4
                            height: width
                            seed: modelData.seed; rarity: modelData.rarity
                            voice: Zoo.playerName; lodLevel: 1
                            MouseArea {
                                anchors.fill: parent
                                onClicked: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"),
                                                          { seed: modelData.seed, rarity: modelData.rarity })
                            }
                        }
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Hatch a blob — %1 🍞").arg(Zoo.hatchCost)
                enabled: Zoo.canHatch
                onClicked: Zoo.hatchBlob()
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                text: Zoo.canHatch ? qsTr("Go on. You've earned it.")
                                   : qsTr("Not enough crumbs. Go be productive; they'll wait.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
            }

            // Fun fact of the day.
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: factCol.height + 2 * Theme.paddingMedium
                radius: Theme.paddingMedium
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.12)
                Column {
                    id: factCol
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.paddingLarge
                    width: parent.width - 2 * Theme.paddingLarge
                    spacing: Theme.paddingSmall
                    Label { text: qsTr("Fun fact, allegedly"); color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeExtraSmall }
                    Label { width: parent.width; wrapMode: Text.Wrap; text: Zoo.funFact
                            color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
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
