import QtQuick 2.6
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import "../specimens"

// The zoo's big moments, played in place: the home page freezes and blurs, and a little 2D scene
// runs in the foreground over it. A farewell blob shoulders its bindle and walks off the edge; a
// milestone throws confetti; the Quest Beast sweeps in and eats a resident. One source of truth for
// "blur + foreground animation" so every ceremony feels of a piece.
//
// Usage:  overlay.play(ceremony)      -> runs a ceremony scene, then emits finished()
//         overlay.playPredator(n)     -> runs the eat scene, then emits predatorDone()
Item {
    id: root
    anchors.fill: parent
    z: 1000
    visible: shade > 0.001

    // The home content to freeze & blur behind the scene (usually the page's SilicaFlickable).
    property Item blurSource

    property var ceremony: ({})
    property int predatorCount: 0
    property string scene: ""          // "farewell" | "party" | "predator" | "chapter"
    property real shade: 0             // 0 hidden, 1 fully blurred+dim
    readonly property bool busy: shade > 0.001

    // A revealed Almanac chapter (the story arrives as a moment, not a menu item).
    property string chapterId: ""
    property string chapterTitle: ""
    property string chapterBody: ""

    signal finished()                  // a ceremony scene ended
    signal predatorDone()              // the eat scene ended
    signal chapterDone()               // an Almanac chapter reveal was dismissed

    function play(c) {
        root.ceremony = c || ({})
        root.scene = (root.ceremony.kind === "farewell") ? "farewell" : "party"
        _begin()
    }
    function playPredator(n) {
        if (n <= 0) { root.predatorDone(); return }
        root.predatorCount = n
        root.scene = "predator"
        _begin()
    }
    // Chapters wait for the reader (not auto-timed), so they don't go through _begin().
    function playChapter(ch) {
        root.chapterId = (ch && ch.id) ? ch.id : ""
        root.chapterTitle = (ch && ch.title) ? ch.title : ""
        root.chapterBody = (ch && ch.body) ? ch.body : ""
        root.scene = "chapter"
        snapshot.scheduleUpdate()
        chapterIn.restart()
    }

    function _begin() {
        snapshot.scheduleUpdate()      // freeze the current home frame
        if (root.scene === "farewell") farewellAnim.restart()
        else if (root.scene === "party") partyAnim.restart()
        else predatorAnim.restart()
    }

    // ---- Frozen, blurred backdrop -----------------------------------------------------------
    ShaderEffectSource {
        id: snapshot
        anchors.fill: parent
        sourceItem: root.blurSource
        live: false
        hideSource: false
        visible: false
    }
    FastBlur {
        anchors.fill: parent
        source: snapshot
        radius: 48 * root.shade
        opacity: root.shade
    }
    Rectangle { anchors.fill: parent; color: "#0B0D12"; opacity: root.shade * 0.5 }

    // Swallow taps while a scene is running so the page underneath stays untouched.
    MouseArea { anchors.fill: parent; enabled: root.visible }

    // ---- Caption (ceremony/predator scenes only; chapters have their own centred view) --------
    Column {
        visible: root.scene !== "chapter"
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom
                  bottomMargin: Theme.paddingLarge * 3 }
        width: parent.width - 2 * Theme.horizontalPageMargin
        spacing: Theme.paddingSmall
        opacity: root.shade
        Label {
            width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
            visible: text.length > 0
            text: root.scene === "predator" ? qsTr("The Quest Beast")
                                            : (root.ceremony.title ? root.ceremony.title : "")
            color: Theme.highlightColor; font.pixelSize: Theme.fontSizeLarge
        }
        Label {
            width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
            visible: text.length > 0
            text: root.scene === "predator"
                  ? qsTr("The Quest Beast ate %1. Overdue quests have consequences. Mild ones.").arg(
                        root.predatorCount === 1 ? qsTr("a blob")
                                                 : qsTr("%1 blobs").arg(root.predatorCount))
                  : (root.ceremony.body ? root.ceremony.body : "")
            color: "#F6EFDD"; font.pixelSize: Theme.fontSizeSmall
        }
    }

    // ---- Stage geometry ---------------------------------------------------------------------
    property real blobSize: root.width * 0.42
    property real stageY: root.height * 0.34

    // ---- Farewell: the departing blob shoulders a bindle and walks off the right edge --------
    Item {
        id: walker
        width: root.blobSize; height: root.blobSize
        y: root.stageY
        visible: root.scene === "farewell" && root.shade > 0.01

        BlobSpecimen {
            id: farewellBlob
            anchors.fill: parent
            seed: root.ceremony.seed !== undefined ? root.ceremony.seed : 20260714
            rarity: root.ceremony.rarity !== undefined ? root.ceremony.rarity : "common"
            styleOverride: Zoo.blobStyle
            voice: Zoo.playerName
            lodLevel: 1
        }

        // A little hobo bindle: a stick over the shoulder holding a knotted, polka-dot cloth sack.
        Item {
            id: bindle
            width: root.blobSize * 0.66; height: width
            x: root.blobSize * 0.50; y: -root.blobSize * 0.16
            opacity: 0
            // The stick, resting on the shoulder and angling up behind the sack.
            Rectangle {
                width: parent.width * 0.94; height: Math.max(4, root.blobSize * 0.04)
                radius: height / 2; color: "#6E4322"
                x: 0; y: parent.height * 0.52
                rotation: -34; transformOrigin: Item.Left; antialiasing: false
            }
            // A pale nub where the stick tip pokes out above the knot.
            Rectangle {
                width: Math.max(3, root.blobSize * 0.05); height: width; radius: width / 2
                color: "#8A5A2E"; x: parent.width * 0.80; y: parent.height * 0.02; antialiasing: false
            }
            // The cloth sack (round-ish body + a tied knot on top + polka dots).
            Item {
                id: sack
                width: root.blobSize * 0.32; height: width
                x: parent.width * 0.56; y: parent.height * 0.06
                // Two little corners of tied cloth forming the knot.
                Rectangle { width: parent.width * 0.20; height: width; color: "#8E2A1C"
                            x: parent.width * 0.26; y: parent.height * 0.02; rotation: 45; antialiasing: false }
                Rectangle { width: parent.width * 0.20; height: width; color: "#8E2A1C"
                            x: parent.width * 0.52; y: parent.height * 0.02; rotation: 45; antialiasing: false }
                // The bundle body.
                Rectangle {
                    x: 0; y: parent.height * 0.16
                    width: parent.width; height: parent.height * 0.84
                    radius: width * 0.42; color: "#C0392B"
                    border.width: Math.max(1, root.blobSize * 0.012); border.color: "#8E2A1C"
                    antialiasing: false
                }
                // Polka dots.
                Rectangle { width: parent.width * 0.15; height: width; radius: width / 2; color: "#F6EFDD"
                            x: parent.width * 0.24; y: parent.height * 0.52; antialiasing: false }
                Rectangle { width: parent.width * 0.12; height: width; radius: width / 2; color: "#F6EFDD"
                            x: parent.width * 0.58; y: parent.height * 0.40; antialiasing: false }
                Rectangle { width: parent.width * 0.10; height: width; radius: width / 2; color: "#F6EFDD"
                            x: parent.width * 0.44; y: parent.height * 0.70; antialiasing: false }
            }
        }
    }

    // ---- Party: the celebrated blob hops in a shower of confetti -----------------------------
    BlobSpecimen {
        id: partyBlob
        width: root.blobSize; height: width
        x: root.width / 2 - width / 2; y: root.stageY
        visible: root.scene === "party" && root.shade > 0.01
        seed: root.ceremony.seed !== undefined ? root.ceremony.seed : 20260714
        rarity: root.ceremony.rarity !== undefined ? root.ceremony.rarity : "common"
        styleOverride: Zoo.blobStyle
        voice: Zoo.playerName
        lodLevel: 1
    }

    // ---- Predator: a chonky blob sweeps in, opens its maw, EATS a small resident, and leaves --
    BlobSpecimen {
        id: predator
        width: root.width * 0.5; height: width
        y: root.stageY
        visible: root.scene === "predator" && root.shade > 0.01
        seed: 66613
        styleOverride: "chonk"
        voice: qsTr("NOM")
        lodLevel: 0
    }
    // The doomed little resident, sitting at centre stage until the beast reaches it. In front of
    // the predator so we see it, then it shrinks into the open maw.
    BlobSpecimen {
        id: prey
        width: root.blobSize * 0.52; height: width
        x: root.width * 0.5 - width / 2
        y: root.stageY + root.blobSize * 0.24
        transformOrigin: Item.Center
        visible: root.scene === "predator" && root.shade > 0.01
        seed: 424242
        styleOverride: Zoo.blobStyle
        voice: Zoo.playerName
        lodLevel: 1
    }
    // The beast's maw: a dark mouth that yawns open on the chomp (teeth and all), then snaps shut.
    Item {
        id: maw
        visible: root.scene === "predator" && root.shade > 0.01 && openH > 0.5
        property real openH: 0
        width: root.blobSize * 0.5; height: openH
        x: root.width * 0.5 - width / 2
        y: root.stageY + root.blobSize * 0.16
        Rectangle {
            anchors.fill: parent; color: "#0A0B0F"
            radius: Math.min(width, height) * 0.4; antialiasing: false
            border.width: Math.max(1, root.blobSize * 0.015); border.color: "#2A0E0A"
        }
        // A row of little teeth along the top lip.
        Row {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: -root.blobSize * 0.02 }
            spacing: maw.width * 0.10
            Repeater {
                model: 4
                delegate: Rectangle { width: maw.width * 0.10; height: width; color: "#F6EFDD"; antialiasing: false }
            }
        }
    }

    ConfettiBurst { id: confetti }

    // ---- Chapter reveal: reflective, tap Continue to dismiss (waits for the reader) ----------
    Item {
        id: chapterView
        anchors.fill: parent
        visible: root.scene === "chapter" && root.shade > 0.01
        opacity: root.shade
        Column {
            id: chapterCol
            width: parent.width - 2 * Theme.horizontalPageMargin
            anchors.centerIn: parent
            spacing: Theme.paddingLarge
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                text: qsTr("The Keeper's Almanac")
                color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                text: root.chapterTitle; color: Theme.highlightColor; font.pixelSize: Theme.fontSizeExtraLarge
            }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                text: root.chapterBody; color: "#F6EFDD"; font.pixelSize: Theme.fontSizeMedium
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Continue"); onClicked: chapterOut.restart()
            }
        }
    }

    // ---- Scene timelines --------------------------------------------------------------------
    SequentialAnimation {
        id: chapterIn
        NumberAnimation { target: root; property: "shade"; to: 1; duration: 420; easing.type: Easing.OutQuad }
    }
    SequentialAnimation {
        id: chapterOut
        NumberAnimation { target: root; property: "shade"; to: 0; duration: 360 }
        ScriptAction { script: root.chapterDone() }
    }
    SequentialAnimation {
        id: farewellAnim
        ScriptAction { script: { walker.x = root.width / 2 - walker.width / 2; bindle.opacity = 0 } }
        NumberAnimation { target: root; property: "shade"; to: 1; duration: 320 }
        PauseAnimation { duration: 300 }
        ScriptAction { script: farewellBlob.react() }                  // a little hop, one last word
        NumberAnimation { target: bindle; property: "opacity"; to: 1; duration: 420 }   // hoists the bundle
        PauseAnimation { duration: 650 }
        NumberAnimation { target: walker; property: "x"; to: root.width + walker.width * 0.2
                          duration: 2600; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "shade"; to: 0; duration: 360 }
        ScriptAction { script: root.finished() }
    }

    SequentialAnimation {
        id: partyAnim
        NumberAnimation { target: root; property: "shade"; to: 1; duration: 320 }
        ScriptAction { script: confetti.fireAt(root.width / 2, root.stageY + root.blobSize * 0.3) }
        ScriptAction { script: partyBlob.poke() }
        PauseAnimation { duration: 700 }
        ScriptAction { script: partyBlob.poke() }
        PauseAnimation { duration: 900 }
        NumberAnimation { target: root; property: "shade"; to: 0; duration: 360 }
        ScriptAction { script: root.finished() }
    }

    SequentialAnimation {
        id: predatorAnim
        ScriptAction { script: { predator.x = -predator.width; prey.scale = 1; prey.opacity = 1
                                 prey.y = root.stageY + root.blobSize * 0.24; maw.openH = 0 } }
        NumberAnimation { target: root; property: "shade"; to: 1; duration: 300 }
        // The little one notices, gives a nervous hop.
        ScriptAction { script: prey.react() }
        PauseAnimation { duration: 250 }
        // The beast sweeps in and arrives right on top of the prey.
        NumberAnimation { target: predator; property: "x"; to: root.width * 0.5 - predator.width / 2
                          duration: 850; easing.type: Easing.OutQuad }
        // The maw yawns open...
        NumberAnimation { target: maw; property: "openH"; to: root.blobSize * 0.5; duration: 200; easing.type: Easing.OutQuad }
        ScriptAction { script: predator.react() }                     // a big chomp + "NOM"
        // ...the mini blob is pulled in and squashed down to nothing inside it...
        ParallelAnimation {
            NumberAnimation { target: prey; property: "y"; to: maw.y + maw.openH * 0.4; duration: 240; easing.type: Easing.InQuad }
            NumberAnimation { target: prey; property: "scale"; to: 0.0; duration: 260; easing.type: Easing.InBack }
            NumberAnimation { target: prey; property: "opacity"; to: 0.0; duration: 260 }
        }
        // ...and the jaws snap shut.
        NumberAnimation { target: maw; property: "openH"; to: 0; duration: 160; easing.type: Easing.InQuad }
        PauseAnimation { duration: 650 }
        NumberAnimation { target: predator; property: "x"; to: root.width; duration: 700; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "shade"; to: 0; duration: 300 }
        ScriptAction { script: { root.predatorCount = 0; root.predatorDone() } }
    }
}
