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

    // Enclosure props: biome objects + your owned decorations, at stable positions.
    property var props: buildProps(Zoo.selectedTheme, Zoo.shopItems)
    function _pf(i, a) {
        var h = Math.sin((i + 1) * (a === 0 ? 12.9898 : 78.233)) * 43758.5453
        h = h - Math.floor(h)
        return a === 0 ? 0.08 + h * 0.84 : 0.36 + h * 0.54
    }
    function _imgProp(name, idx) {
        var A = {
            tree:     { sizeF: 0.22, overhead: true,  solid: false, cr: 0 },
            pine:     { sizeF: 0.20, overhead: true,  solid: false, cr: 0 },
            building: { sizeF: 0.26, overhead: true,  solid: true,  cr: 0.11 },
            house:    { sizeF: 0.26, overhead: true,  solid: true,  cr: 0.11 },
            rock:     { sizeF: 0.13, overhead: false, solid: true,  cr: 0.06 },
            bush:     { sizeF: 0.13, overhead: false, solid: true,  cr: 0.05 },
            cactus:   { sizeF: 0.14, overhead: false, solid: true,  cr: 0.05 },
            lantern:  { sizeF: 0.08, overhead: false, solid: true,  cr: 0.04 }
        }
        var a = A[name] || A.rock
        return { kind: "img", src: Qt.resolvedUrl("../images/props/" + name + ".png"),
                 xf: _pf(idx, 0), yf: _pf(idx, 1),
                 sizeF: a.sizeF, overhead: a.overhead, solid: a.solid, cr: a.cr }
    }
    function buildProps(theme, shopItems) {
        var TP = {
            grass: ["tree", "tree", "tree", "rock", "bush"], desert: ["cactus", "cactus", "rock", "rock"],
            farwest: ["cactus", "rock", "house"], cyberpunk: ["building", "building"],
            snow: ["pine", "pine", "pine", "rock"], night: ["tree", "tree", "rock", "bush"],
            tokyo: ["building", "building", "lantern", "lantern"]
        }
        var list = TP[theme] || []
        var out = []; var idx = 0
        for (var i = 0; i < list.length; i++) out.push(_imgProp(list[i], idx++))
        // Owned decorations become pixel-art sprites placed in the zoo (no clashing emoji).
        if (shopItems) for (var j = 0; j < shopItems.length; j++) {
            if (!shopItems[j].owned) continue
            out.push({ kind: "img", src: Qt.resolvedUrl("../images/props/deco_" + shopItems[j].id + ".png"),
                       xf: _pf(idx, 0), yf: _pf(idx, 1), sizeF: 0.13, overhead: false, solid: true, cr: 0.05 })
            idx++
        }
        return out
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

                // Ground-level props (rocks, bushes, cacti, and your bought objects). Solid: blobs
                // bump into them. Drawn below the blobs, so blobs walk in front.
                Repeater {
                    model: page.props
                    delegate: Item {
                        visible: !modelData.overhead
                        width: biome.width * modelData.sizeF; height: width
                        x: biome.width * modelData.xf - width / 2
                        y: biome.height * modelData.yf - height / 2
                        Image { visible: modelData.kind === "img"; anchors.fill: parent
                                source: modelData.src; fillMode: Image.PreserveAspectFit; smooth: false }
                        Text { visible: modelData.kind === "emoji"; anchors.centerIn: parent
                               text: modelData.emoji; font.pixelSize: Math.max(12, parent.width * 0.85) }
                    }
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
                        // Shoved away from a point (another blob's or a solid prop's centre).
                        function shoveFrom(cx, cy) {
                            var dx = (x + blobSize / 2) - cx, dy = (y + blobSize / 2) - cy
                            var d = Math.sqrt(dx * dx + dy * dy) || 1
                            roamer.dur = 360
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

                // Overhead props (trees, buildings) drawn ABOVE the blobs, so a blob passes under them.
                Repeater {
                    model: page.props
                    delegate: Item {
                        visible: modelData.overhead
                        width: biome.width * modelData.sizeF; height: width
                        x: biome.width * modelData.xf - width / 2
                        y: biome.height * modelData.yf - height * 0.72
                        Image { visible: modelData.kind === "img"; anchors.fill: parent
                                source: modelData.src; fillMode: Image.PreserveAspectFit; smooth: false }
                    }
                }

                // Physics: blobs shove off each other and off solid props, muttering about life.
                Timer {
                    interval: 360; running: Zoo.ownedBlobs.length > 0; repeat: true
                    onTriggered: {
                        var n = roamers.count
                        for (var i = 0; i < n; i++) {
                            var a = roamers.itemAt(i); if (!a) continue
                            for (var j = i + 1; j < n; j++) {
                                var b = roamers.itemAt(j); if (!b) continue
                                var dx = (a.x + a.blobSize / 2) - (b.x + b.blobSize / 2)
                                var dy = (a.y + a.blobSize / 2) - (b.y + b.blobSize / 2)
                                if (Math.sqrt(dx * dx + dy * dy) < (a.blobSize + b.blobSize) * 0.45) {
                                    a.shoveFrom(b.x + b.blobSize / 2, b.y + b.blobSize / 2)
                                    b.shoveFrom(a.x + a.blobSize / 2, a.y + a.blobSize / 2)
                                    if (Math.random() < 0.25) { a.react(); b.react() }
                                }
                            }
                            for (var k = 0; k < page.props.length; k++) {
                                var p = page.props[k]; if (!p.solid) continue
                                var pcx = biome.width * p.xf, pcy = biome.height * p.yf
                                var ex = (a.x + a.blobSize / 2) - pcx, ey = (a.y + a.blobSize / 2) - pcy
                                if (Math.sqrt(ex * ex + ey * ey) < a.blobSize * 0.5 + biome.width * p.cr) {
                                    a.shoveFrom(pcx, pcy)
                                    if (Math.random() < 0.12) a.react()
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
