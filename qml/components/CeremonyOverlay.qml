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
    property string scene: ""          // "farewell" | "party" | "predator"
    property real shade: 0             // 0 hidden, 1 fully blurred+dim
    readonly property bool busy: shade > 0.001

    signal finished()                  // a ceremony scene ended
    signal predatorDone()              // the eat scene ended

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

    // ---- Caption ----------------------------------------------------------------------------
    Column {
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

        // A little hobo bindle: a stick over the shoulder with a polka-dot bundle at the end.
        Item {
            id: bindle
            width: root.blobSize * 0.5; height: width
            x: root.blobSize * 0.60; y: -root.blobSize * 0.06
            opacity: 0
            Rectangle {   // the stick
                width: parent.width; height: Math.max(3, root.blobSize * 0.028)
                radius: height / 2; color: "#7A4A22"
                anchors.centerIn: parent; rotation: -32; antialiasing: false
            }
            Item {        // the bundle, at the raised end of the stick
                width: root.blobSize * 0.22; height: width
                x: parent.width * 0.62; y: -parent.height * 0.04
                Rectangle {   // red cloth, tied into a diamond
                    anchors.centerIn: parent
                    width: parent.width * 0.78; height: width
                    color: "#C0392B"; rotation: 45; radius: 2; antialiasing: false
                }
                Rectangle { width: parent.width * 0.13; height: width; radius: width / 2; color: "#F6EFDD"
                            x: parent.width * 0.34; y: parent.height * 0.42; antialiasing: false }
                Rectangle { width: parent.width * 0.11; height: width; radius: width / 2; color: "#F6EFDD"
                            x: parent.width * 0.56; y: parent.height * 0.30; antialiasing: false }
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

    // ---- Predator: a chonky blob sweeps across, chomps, and leaves ---------------------------
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

    ConfettiBurst { id: confetti }

    // ---- Scene timelines --------------------------------------------------------------------
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
        ScriptAction { script: predator.x = -predator.width }
        NumberAnimation { target: root; property: "shade"; to: 1; duration: 300 }
        NumberAnimation { target: predator; property: "x"; to: root.width * 0.5 - predator.width / 2
                          duration: 800; easing.type: Easing.OutQuad }
        ScriptAction { script: predator.react() }                     // a big chomp + "NOM"
        PauseAnimation { duration: 900 }
        NumberAnimation { target: predator; property: "x"; to: root.width; duration: 700; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "shade"; to: 0; duration: 300 }
        ScriptAction { script: { root.predatorCount = 0; root.predatorDone() } }
    }
}
