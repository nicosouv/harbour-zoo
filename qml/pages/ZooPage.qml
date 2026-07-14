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

    // A single looping phase drives the gentle sway of foliage (each prop offsets it, so they don't
    // move in lockstep). Cheap: one animated number, read by every swaying prop.
    property real swayPhase: 0
    NumberAnimation on swayPhase {
        from: 0; to: 6.2831853; duration: 6000; loops: Animation.Infinite; running: true
    }
    function _pf(i, a) {
        var h = Math.sin((i + 1) * (a === 0 ? 12.9898 : 78.233)) * 43758.5453
        h = h - Math.floor(h)
        return a === 0 ? 0.08 + h * 0.84 : 0.36 + h * 0.54
    }
    function _imgProp(name, idx) {
        var A = {
            tree:     { sizeF: 0.22, overhead: true,  solid: false, cr: 0,    sway: true },
            pine:     { sizeF: 0.20, overhead: true,  solid: false, cr: 0,    sway: true },
            building: { sizeF: 0.26, overhead: true,  solid: true,  cr: 0.11, sway: false },
            house:    { sizeF: 0.26, overhead: true,  solid: true,  cr: 0.11, sway: false },
            rock:     { sizeF: 0.13, overhead: false, solid: true,  cr: 0.06, sway: false },
            bush:     { sizeF: 0.13, overhead: false, solid: true,  cr: 0.05, sway: true },
            cactus:   { sizeF: 0.14, overhead: false, solid: true,  cr: 0.05, sway: true },
            lantern:  { sizeF: 0.08, overhead: false, solid: true,  cr: 0.04, sway: false }
        }
        var a = A[name] || A.rock
        return { kind: "img", src: Qt.resolvedUrl("../images/props/" + name + ".png"),
                 xf: _pf(idx, 0), yf: _pf(idx, 1),
                 sizeF: a.sizeF, overhead: a.overhead, solid: a.solid, cr: a.cr, sway: a.sway }
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
                       xf: _pf(idx, 0), yf: _pf(idx, 1), sizeF: 0.13, overhead: false, solid: true, cr: 0.05, sway: false })
            idx++
        }
        return out
    }

    SilicaFlickable {
        id: mainFlick
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Settings"); onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml")) }
            MenuItem { text: qsTr("Shop"); onClicked: pageStack.push(Qt.resolvedUrl("ShopPage.qml")) }
            MenuItem { text: qsTr("Keeper"); onClicked: pageStack.push(Qt.resolvedUrl("KeeperPage.qml")) }
            MenuItem {
                text: Zoo.hasUnreadAlmanac ? qsTr("Almanac •") : qsTr("Almanac")
                onClicked: pageStack.push(Qt.resolvedUrl("AlmanacPage.qml"))
            }
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
                        // Low foliage sways a touch, from its base; solid objects stay put.
                        transform: Rotation {
                            origin.x: width / 2; origin.y: height
                            angle: modelData.sway ? Math.sin(page.swayPhase + index * 1.7) * 1.6 : 0
                        }
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
                        // A speaking blob pops above the overhead props so its bubble is readable.
                        z: blob.speaking ? 10 : 0
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
                        SpecimenView {
                            id: blob
                            anchors.fill: parent
                            seed: modelData.seed; rarity: modelData.rarity; species: modelData.species
                            voice: Zoo.playerName; styleOverride: Zoo.blobStyle; lodLevel: 1
                            MouseArea {
                                anchors.fill: parent
                                onClicked: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"),
                                                          { seed: modelData.seed, rarity: modelData.rarity,
                                                            date: modelData.date, species: modelData.species })
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
                        // Trees rock their canopy gently from the trunk base; buildings don't sway.
                        transform: Rotation {
                            origin.x: width / 2; origin.y: height
                            angle: modelData.sway ? Math.sin(page.swayPhase + index * 1.3) * 2.6 : 0
                        }
                        Image { visible: modelData.kind === "img"; anchors.fill: parent
                                source: modelData.src; fillMode: Image.PreserveAspectFit; smooth: false }
                    }
                }

                // Tiny wandering insects — ambient life, drifting on soft looping paths. Cheap: a few
                // small dots, no particle system. Positions are ephemeral (not part of any identity).
                Repeater {
                    model: 3
                    delegate: Item {
                        id: bug
                        z: 5
                        width: Math.max(3, biome.width * 0.014); height: width
                        property int dur: 3000
                        function bx() { return Math.random() * Math.max(1, biome.width - width) }
                        function by() { return biome.height * 0.26 + Math.random() * Math.max(1, biome.height * 0.60) }
                        Component.onCompleted: { x = bx(); y = by() }
                        Behavior on x { NumberAnimation { duration: bug.dur; easing.type: Easing.InOutSine } }
                        Behavior on y { NumberAnimation { duration: bug.dur; easing.type: Easing.InOutSine } }
                        Timer {
                            interval: 1600 + Math.random() * 2600; running: true; repeat: true
                            onTriggered: { bug.dur = 2200 + Math.random() * 2600; bug.x = bug.bx(); bug.y = bug.by() }
                        }
                        Rectangle {
                            anchors.centerIn: parent; width: parent.width * 0.7; height: width * 0.7
                            radius: width; color: "#1D1F17"; opacity: 0.7; antialiasing: false
                        }
                    }
                }

                // Zoo mood: recent good vs bad habits gently tint the whole scene (warm when you're
                // doing well, cool and murky when the bad habits have been winning).
                Rectangle {
                    anchors.fill: parent
                    color: Zoo.zooMood >= 0 ? "#F2C85C" : "#33456A"
                    opacity: Math.abs(Zoo.zooMood) * 0.22
                    Behavior on opacity { NumberAnimation { duration: 500 } }
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

            // A new page in the story quietly waiting. Gentle, never a red badge — a warm invitation.
            BackgroundItem {
                width: parent.width; height: Theme.itemSizeExtraSmall
                visible: Zoo.hasUnreadAlmanac
                onClicked: pageStack.push(Qt.resolvedUrl("AlmanacPage.qml"))
                Label {
                    x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.Wrap; text: qsTr("A new page appeared in the Almanac.")
                    color: Theme.highlightColor; font.pixelSize: Theme.fontSizeSmall; font.italic: true
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

    // Big moments play here, in place: the page above freezes and blurs while a 2D scene runs on
    // top (a farewell blob walking off with its bindle, a milestone's confetti, the Quest Beast).
    CeremonyOverlay {
        id: ceremonyOverlay
        blurSource: mainFlick
        onFinished: { Zoo.dismissCeremony(ceremony.id); page.advanceIntro() }
        onPredatorDone: page.advanceIntro()
        onChapterDone: { Zoo.markChapterRead(chapterId); page.advanceIntro() }
    }

    Connections {
        target: Zoo
        onHatched: pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"), { seed: seed, rarity: rarity, species: species })
    }

    // First launch: onboarding. Otherwise, show any pending ceremonies (farewells, milestones,
    // birthday, holidays) queued for this launch.
    // Re-run whenever the zoo becomes the top page again (e.g. back from Settings), so freshly
    // queued ceremonies/overdue quests surface without a restart. All checks are self-guarded.
    Component.onCompleted: startupTimer.restart()
    onStatusChanged: if (status === PageStatus.Active) startupTimer.restart()

    // Overdue-quest victims waiting for their (blurred) eat scene, once any ceremonies have played.
    property int _pendingVictims: 0

    // Present the launch's moments one at a time, in order: pending ceremonies, then the Quest
    // Beast, then a freshly-unlocked Almanac chapter. Re-entered after each overlay finishes.
    function advanceIntro() {
        var cs = Zoo.pendingCeremonies()
        if (cs.length > 0) { ceremonyOverlay.play(cs[0]); return }
        if (page._pendingVictims > 0) {
            var n = page._pendingVictims; page._pendingVictims = 0; ceremonyOverlay.playPredator(n); return
        }
        var ch = Zoo.pendingChapter()
        if (ch.id !== undefined) ceremonyOverlay.playChapter(ch)
    }

    Timer {
        id: startupTimer; interval: 40; repeat: false
        onTriggered: {
            if (!Zoo.onboarded) { pageStack.push(Qt.resolvedUrl("OnboardingPage.qml")); return }
            if (ceremonyOverlay.busy) return
            page._pendingVictims += Zoo.processOverdueQuests().length
            page.advanceIntro()
        }
    }
}
