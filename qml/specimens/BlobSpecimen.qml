import QtQuick 2.6

// The hero specimen. A living blob rendered from the seed as a "genome": an ovoid body (not a
// circle), always-visible googly eyes, idle bob, and a springy hop that lands floppy and re-forms.
// It mutters little random words at irregular intervals. Pure QML (no shader) for rock-solid
// rendering on every device. Deterministic look: same seed+rarity => same creature, forever.
Specimen {
    id: root

    readonly property color creamColor: "#F6EFDD"
    readonly property color pupilColor: "#1A1C26"

    // A name it occasionally shouts. Mostly it just mutters nonsense (see _words).
    property string voice: ""
    readonly property var _words: ["blep", "boing", "oi", "hm", "meep", "wot", "hello", "?!",
        "...", "nyoom", "ok", "ee", "hi", "brb", "oof", "mrr", "yes", "no"]

    property var g: buildGenome(seed, rarity)

    // Live, non-persistent motion state.
    property real tt: 0            // idle clock
    property real hopY: 0          // vertical hop offset
    property real sx: 1.0          // horizontal squash
    property real sy: 1.0          // vertical squash
    property real eyeOpen: 1.0
    readonly property real idleBob: Math.sin(tt * 1.6) * (field.height * 0.012)

    // Gaze: follow the finger while pressed, else a gentle wander.
    property bool looking: false
    property real touchX: 0
    property real touchY: 0
    readonly property real gazeX: looking ? touchX : 0.4 * Math.sin(tt * 0.7)
    readonly property real gazeY: looking ? touchY : 0.25 * Math.sin(tt * 0.9 + 1.0)

    readonly property var _names: ["Sir Reginald Ooze", "Beans", "The Understudy", "Gerald, Probably",
        "Small Cousin", "The Committee", "Blob Ross", "Modest Steve", "Uncertain Todd",
        "Professor Squish", "Nap Enthusiast", "The Damp One"]
    readonly property var _lore: ["A blob that is understood.", "The wobble is the whole idea.",
        "Mostly still, occasionally delighted.", "Small and content beats large and worried.",
        "Here, which is enough.", "Came for the crumbs, stayed for the vibe."]
    readonly property string displayName: _names[Math.abs(seed) % _names.length]
    readonly property string lore: _lore[Math.abs(Math.floor(seed / 7)) % _lore.length]

    NumberAnimation on tt {
        from: 0; to: 6.2831853; duration: 4200
        loops: Animation.Infinite; running: root.lodLevel < 2
    }

    // ---- Genome (deterministic, seed-driven) ------------------------------------------------
    function rngFromSeed(s) {
        var a = (s >>> 0) || 1; // mulberry32
        return function () {
            a = (a + 0x6D2B79F5) | 0;
            var t = Math.imul(a ^ (a >>> 15), 1 | a);
            t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
            return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
        };
    }

    function buildGenome(seed, rarity) {
        var r = rngFromSeed(seed);
        function range(lo, hi) { return lo + (hi - lo) * r(); }
        function pick(arr) { return arr[Math.floor(r() * arr.length)]; }

        // Ovoid body: width and height differ (egg / squat / tall). Some blobs are just bigger.
        var bodyW = range(0.62, 0.86);
        var bodyH = bodyW * range(0.82, 1.28);
        var bodyScale = range(0.72, 1.0);

        // Eyes — not necessarily round. aspect >1 = wide/sleepy, <1 = tall; corner low = almond.
        var eyeCount = pick([1, 2, 2, 2, 2, 3]);
        var eyes = [];
        var spacing = range(0.15, 0.24);
        var eyeY = range(-0.12, -0.02);
        var eyeSize = range(0.20, 0.30);
        if (eyeCount === 1) {
            eyes.push({ x: 0, y: eyeY, s: eyeSize * 1.25 });
        } else if (eyeCount === 2) {
            eyes.push({ x: -spacing, y: eyeY, s: eyeSize });
            eyes.push({ x: spacing, y: eyeY + range(-0.02, 0.02), s: eyeSize });
        } else {
            eyes.push({ x: -spacing, y: eyeY, s: eyeSize * 0.82 });
            eyes.push({ x: 0, y: eyeY - 0.05, s: eyeSize * 0.82 });
            eyes.push({ x: spacing, y: eyeY, s: eyeSize * 0.82 });
        }

        var wander = (rarity === "common") ? 0.05 : (rarity === "uncommon" ? 0.13 : 0.5);
        var h = (0.62 + range(-wander, wander) + 1) % 1;
        var sat = (rarity === "common") ? range(0.22, 0.36) : range(0.4, 0.72);
        var lig = range(0.30, 0.44);

        return {
            bodyW: bodyW, bodyH: bodyH, bodyScale: bodyScale,
            eyes: eyes,
            eyeAspect: range(0.72, 1.7),
            eyeCorner: range(0.28, 0.5),
            eyeTilt: Math.floor(range(0, 22)),
            mirrorTilt: (r() < 0.85),
            pupilRatio: range(0.36, 0.5),
            pupilAspect: range(0.62, 1.18),
            pupilCorner: range(0.34, 0.5),
            blinkMs: Math.floor(range(2600, 6000)),
            hopMinMs: Math.floor(range(1400, 2600)),
            hopVarMs: Math.floor(range(1800, 4200)),
            body: Qt.hsla(h, sat, lig, 1),
            accent: Qt.hsla((h + 0.5) % 1, 0.6, 0.6, 1),
            temperament: pick(["shy", "hyper", "sleepy", "smug", "nervous", "zen"])
        };
    }

    // ---- Behaviour --------------------------------------------------------------------------
    function hop() {
        if (root.lodLevel >= 2) return;
        hopAnim.restart();
        hopTimer.interval = g.hopMinMs + Math.floor(Math.random() * g.hopVarMs); // irregular
    }

    function speak() {
        if (root.lodLevel >= 2) return;
        bubble.say = (root.voice && root.voice.length > 0 && Math.random() < 0.25)
                     ? root.voice.toUpperCase() + "!"
                     : root._words[Math.floor(Math.random() * root._words.length)];
        bubbleAnim.restart();
        speakTimer.interval = 2500 + Math.floor(Math.random() * 8000); // irregular, not periodic
    }

    function poke() {
        splatAnim.restart();
        wideAnim.restart();
        var m = root.memory || {};
        m.pokes = (m.pokes || 0) + 1;
        root.memory = m;
        root.persist(m);
        if (m.pokes % 50 === 0) puffAnim.restart();  // burp secret
        else if (Math.random() < 0.6) speak();        // poking is rude; it comments
    }

    // ---- Drawing ----------------------------------------------------------------------------
    Item {
        id: field
        width: Math.min(root.width, root.height)
        height: width
        anchors.centerIn: parent

        // Everything that moves as one creature (body + eyes). Squashes onto its base.
        Item {
            id: visual
            anchors.fill: parent
            transform: [
                Scale {
                    origin.x: visual.width / 2; origin.y: visual.height
                    xScale: root.sx; yScale: root.sy
                },
                Translate { y: root.hopY + root.idleBob }
            ]

            // Ground shadow (shrinks as it hops, for lift).
            Rectangle {
                width: body.width * (0.86 - root.hopY / field.height * 0.6)
                height: width * 0.20
                radius: height / 2
                color: "#20233A"
                opacity: 0.22
                x: field.width / 2 - width / 2
                y: body.y + body.height - height * 0.4
            }

            // Ovoid body (NOT a circle): width != height, fully rounded => egg/capsule.
            Rectangle {
                id: body
                width: field.width * g.bodyW * g.bodyScale
                height: field.width * g.bodyH * g.bodyScale
                radius: Math.min(width, height) / 2
                x: field.width / 2 - width / 2
                y: field.height * (0.52 + (1 - g.bodyScale) * 0.2) - height / 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(g.body, 1.22) }
                    GradientStop { position: 1.0; color: Qt.darker(g.body, 1.18) }
                }

                // soft top-left sheen
                Rectangle {
                    width: parent.width * 0.34; height: parent.height * 0.24
                    radius: Math.min(width, height) / 2
                    color: root.creamColor
                    opacity: 0.12
                    x: parent.width * 0.16; y: parent.height * 0.12
                }
            }

            // Eyes — always visible, ovoid, gaze-tracking, blinking.
            Repeater {
                model: g.eyes
                delegate: Item {
                    id: eye
                    property var e: modelData
                    property real base: body.width * e.s
                    property real ew: base * g.eyeAspect
                    property real eh: base / g.eyeAspect
                    width: ew
                    height: eh
                    x: body.x + body.width * (0.5 + e.x) - ew / 2
                    y: body.y + body.height * (0.5 + e.y) - eh / 2
                    rotation: g.eyeTilt * (g.mirrorTilt ? (e.x < 0 ? -1 : (e.x > 0 ? 1 : 0)) : 1)
                    transformOrigin: Item.Center

                    Rectangle { // white
                        width: eye.ew
                        height: eye.eh * root.eyeOpen
                        anchors.centerIn: parent
                        radius: Math.min(width, height) * g.eyeCorner
                        color: root.creamColor
                    }
                    Rectangle { // pupil
                        property real pw: Math.min(eye.ew, eye.eh) * g.pupilRatio
                        width: pw * g.pupilAspect
                        height: pw / g.pupilAspect
                        radius: Math.min(width, height) * g.pupilCorner
                        color: root.pupilColor
                        visible: root.eyeOpen > 0.35
                        x: eye.ew * 0.5 - width / 2 + root.gazeX * eye.ew * 0.18
                        y: eye.eh * 0.5 - height / 2 + root.gazeY * eye.eh * 0.18
                        Rectangle { // catch-light
                            width: parent.width * 0.32; height: parent.height * 0.32
                            radius: Math.min(width, height) / 2
                            color: root.creamColor
                            x: parent.width * 0.16; y: parent.height * 0.14
                        }
                    }
                }
            }

            // Burp puff (50-poke secret).
            Rectangle {
                id: puff
                anchors.horizontalCenter: body.horizontalCenter
                y: body.y - field.height * 0.05
                width: field.width * 0.18; height: width; radius: width / 2
                color: g.accent
                opacity: 0
                scale: 0.4
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: { root.looking = true; root.updateGaze(mouse) }
        onPositionChanged: if (pressed) root.updateGaze(mouse)
        onReleased: root.looking = false
        onCanceled: root.looking = false
        onClicked: root.poke()
    }

    function updateGaze(mouse) {
        var cx = field.x + field.width / 2;
        var cy = field.y + field.height / 2;
        root.touchX = Math.max(-1, Math.min(1, (mouse.x - cx) / (field.width / 2)));
        root.touchY = Math.max(-1, Math.min(1, (mouse.y - cy) / (field.height / 2)));
    }

    // ---- Speech bubble ----------------------------------------------------------------------
    Rectangle {
        id: bubble
        property string say: ""
        color: root.creamColor
        radius: height * 0.34
        width: bubbleLabel.implicitWidth + field.width * 0.14
        height: bubbleLabel.implicitHeight + field.width * 0.07
        x: field.x + field.width * 0.5 - width / 2
        y: field.y + field.height * 0.10 - height
        opacity: 0
        scale: 0.6
        transformOrigin: Item.Bottom
        Text {
            id: bubbleLabel
            anchors.centerIn: parent
            text: bubble.say
            color: root.pupilColor
            font.pixelSize: Math.max(12, field.width * 0.12)
            font.bold: true
        }
        Rectangle { // tail
            width: field.width * 0.06; height: width
            color: root.creamColor
            rotation: 45
            x: bubble.width * 0.5 - width / 2
            y: bubble.height - height / 2
        }
    }

    // ---- Animations -------------------------------------------------------------------------
    SequentialAnimation {  // hop: crouch, launch+stretch, fall, floppy splat, springy re-form
        id: hopAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "sy"; to: 0.86; duration: 90 }
            NumberAnimation { target: root; property: "sx"; to: 1.10; duration: 90 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "hopY"; to: -field.height * 0.22
                duration: 260; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "sy"; to: 1.16; duration: 200 }
            NumberAnimation { target: root; property: "sx"; to: 0.90; duration: 200 }
        }
        NumberAnimation { target: root; property: "hopY"; to: 0; duration: 230; easing.type: Easing.InQuad }
        ParallelAnimation { // land flasque
            NumberAnimation { target: root; property: "sy"; to: 0.70; duration: 70 }
            NumberAnimation { target: root; property: "sx"; to: 1.24; duration: 70 }
        }
        ParallelAnimation { // re-form, jelly
            NumberAnimation { target: root; property: "sy"; to: 1.0; duration: 750; easing.type: Easing.OutElastic }
            NumberAnimation { target: root; property: "sx"; to: 1.0; duration: 750; easing.type: Easing.OutElastic }
        }
    }
    SequentialAnimation { // poke reaction (squish)
        id: splatAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "sy"; to: 0.78; duration: 80 }
            NumberAnimation { target: root; property: "sx"; to: 1.18; duration: 80 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "sy"; to: 1.0; duration: 620; easing.type: Easing.OutElastic }
            NumberAnimation { target: root; property: "sx"; to: 1.0; duration: 620; easing.type: Easing.OutElastic }
        }
    }
    SequentialAnimation {
        id: wideAnim
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.3; duration: 90 }
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.0; duration: 260; easing.type: Easing.OutBack }
    }
    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: root; property: "eyeOpen"; to: 0.08; duration: 70; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.0; duration: 110; easing.type: Easing.OutQuad }
    }
    SequentialAnimation {
        id: bubbleAnim
        ParallelAnimation {
            NumberAnimation { target: bubble; property: "opacity"; to: 1.0; duration: 150 }
            NumberAnimation { target: bubble; property: "scale"; to: 1.0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 3.0 }
        }
        PauseAnimation { duration: 1400 }
        ParallelAnimation {
            NumberAnimation { target: bubble; property: "opacity"; to: 0.0; duration: 260 }
            NumberAnimation { target: bubble; property: "scale"; to: 0.6; duration: 260 }
        }
    }
    SequentialAnimation {
        id: puffAnim
        ParallelAnimation {
            NumberAnimation { target: puff; property: "opacity"; from: 0.7; to: 0; duration: 600 }
            NumberAnimation { target: puff; property: "scale"; from: 0.4; to: 1.6; duration: 600; easing.type: Easing.OutQuad }
        }
    }

    // ---- Irregular timers -------------------------------------------------------------------
    Timer { interval: g.blinkMs; running: root.lodLevel < 2; repeat: true; onTriggered: blinkAnim.restart() }
    Timer { id: hopTimer; interval: g.hopMinMs; running: root.lodLevel < 2; repeat: true; onTriggered: root.hop() }
    Timer { id: speakTimer; interval: 3000 + Math.abs(root.seed % 6000); running: root.lodLevel < 2; repeat: true; onTriggered: root.speak() }
}
