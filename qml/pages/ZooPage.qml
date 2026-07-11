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

    // Hidden easter eggs: tap something `threshold` times for a one-time crumb reward.
    property var _eggTaps: ({})
    function tapEgg(id, threshold, crumbs) {
        var n = (_eggTaps[id] || 0) + 1
        _eggTaps[id] = n
        if (n >= threshold) {
            _eggTaps[id] = 0
            if (Zoo.claimEasterEgg(id, crumbs)) confetti.fireAt(page.width / 2, page.height * 0.5)
        }
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

            // Status row, tappable to the Keeper page (a button in addition to the pull-down).
            BackgroundItem {
                width: parent.width; height: Theme.itemSizeExtraSmall
                onClicked: pageStack.push(Qt.resolvedUrl("KeeperPage.qml"))
                Row {
                    anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                    spacing: Theme.paddingLarge
                    Label { text: "🍞 " + Zoo.crumbs; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                    Label { text: "🥚 " + Zoo.ownedBlobs.length; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                    Label { text: "🔥 " + Zoo.streak; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                }
                Row {
                    anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                    spacing: Theme.paddingSmall
                    Label { text: qsTr("Keeper"); color: Theme.highlightColor; font.pixelSize: Theme.fontSizeExtraSmall
                            anchors.verticalCenter: parent.verticalCenter }
                    Image { source: "image://theme/icon-m-right"; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // Prominent link to the useful loop.
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Today's tasks")
                onClicked: pageStack.push(Qt.resolvedUrl("TodayPage.qml"))
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
                    id: roamers
                    model: Zoo.ownedBlobs
                    delegate: Item {
                        id: roamer
                        property real blobSize: (biome.width / 7) * Zoo.blobScale
                        property int  dur: 4000
                        width: blobSize; height: blobSize
                        function rx() { return Math.random() * Math.max(1, biome.width - blobSize) }
                        function ry() { return biome.height * 0.34 + Math.random() * Math.max(1, biome.height * 0.60 - blobSize) }
                        function clampx(v) { return Math.max(0, Math.min(biome.width - blobSize, v)) }
                        function clampy(v) { return Math.max(biome.height * 0.30, Math.min(biome.height * 0.62, v)) }
                        Component.onCompleted: { x = rx(); y = ry() }
                        Behavior on x { NumberAnimation { duration: roamer.dur; easing.type: Easing.InOutSine } }
                        Behavior on y { NumberAnimation { duration: roamer.dur; easing.type: Easing.InOutSine } }
                        Timer {
                            interval: 2600 + Math.random() * 4000; running: true; repeat: true
                            onTriggered: { roamer.dur = 4000 + Math.random() * 5000; roamer.x = roamer.rx(); roamer.y = roamer.ry() }
                        }
                        // Shoved away from another blob it bumped into.
                        function shove(ox, oy) {
                            var dx = x - ox, dy = y - oy
                            var d = Math.sqrt(dx * dx + dy * dy) || 1
                            roamer.dur = 420
                            x = clampx(x + dx / d * blobSize * 0.7)
                            y = clampy(y + dy / d * blobSize * 0.7)
                        }
                        function react() { blob.react() }
                        BlobSpecimen {
                            id: blob
                            anchors.fill: parent
                            seed: modelData.seed; rarity: modelData.rarity
                            voice: Zoo.playerName; styleOverride: Zoo.blobStyle; lodLevel: 1
                            MouseArea {
                                anchors.fill: parent
                                onClicked: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"),
                                                          { seed: modelData.seed, rarity: modelData.rarity, date: modelData.date })
                            }
                        }
                    }
                }

                // Cheap "physics": when two blobs get too close they shove apart and (sometimes)
                // exchange a weary remark about existence.
                Timer {
                    interval: 380; running: Zoo.ownedBlobs.length > 1; repeat: true
                    onTriggered: {
                        var n = roamers.count
                        for (var i = 0; i < n; i++) {
                            var a = roamers.itemAt(i); if (!a) continue
                            for (var j = i + 1; j < n; j++) {
                                var b = roamers.itemAt(j); if (!b) continue
                                var dx = (a.x + a.blobSize / 2) - (b.x + b.blobSize / 2)
                                var dy = (a.y + a.blobSize / 2) - (b.y + b.blobSize / 2)
                                var dist = Math.sqrt(dx * dx + dy * dy)
                                if (dist < (a.blobSize + b.blobSize) * 0.45) {
                                    a.shove(b.x, b.y); b.shove(a.x, a.y)
                                    if (Math.random() < 0.25) { a.react(); b.react() }
                                }
                            }
                        }
                    }
                }
            }

            // The quiet part. Small, secondary, easy to skim past — until one day it isn't.
            // (Secretly: tap it seven times for a little something.)
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                visible: Zoo.reflection.length > 0
                wrapMode: Text.Wrap; text: Zoo.reflection
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
                font.italic: true
                MouseArea { anchors.fill: parent; onClicked: page.tapEgg("reflection", 7, 77) }
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

            // Fun fact of the day. (Tap it twenty times if you're the sort of person who does that.)
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
                MouseArea { anchors.fill: parent; onClicked: page.tapEgg("funfact", 20, 200) }
            }
        }
        VerticalScrollDecorator {}
    }

    ConfettiBurst { id: confetti }

    Connections {
        target: Zoo
        onHatched: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"), { seed: seed, rarity: rarity })
    }

    // First launch: send the keeper through onboarding before they see the (empty) zoo.
    Component.onCompleted: if (!Zoo.onboarded) onboardTimer.start()
    Timer {
        id: onboardTimer; interval: 1; repeat: false
        onTriggered: pageStack.push(Qt.resolvedUrl("OnboardingPage.qml"))
    }
}
