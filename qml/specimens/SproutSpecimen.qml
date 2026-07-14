import QtQuick 2.6

// A crisp PIXEL-ART potted sprout, generated from the seed. A different animal from the Blob: a
// vertical little plant with cream googly eyes on its bud. Alive at rest (it sways gently), answers
// touch (a spring wobble + wide eyes), and has a secret (enough pokes and it blooms a flower).
// Pure QML squares (no shader, no smoothing) => identical on every device, deterministic per seed.
Specimen {
    id: root

    property string voice: ""
    property string styleOverride: ""     // accepted for API parity with the host; unused here
    readonly property var _words: ["blep", "hi", "hm", "meep", "ok", "psst", "leaf", "sprout", "...", "eep"]
    readonly property var _quips: ["mind the roots", "photosynthesising", "a bit thirsty", "growing, slowly",
        "nice light today", "leaf me alone", "just vibing", "rooted here", "such is life", "green and content"]
    readonly property var _names: ["Sprig", "Mister Leaf", "Fernanda", "The Understudy Plant", "Beansprout",
        "Photosynthetic Steve", "Little Chlorophyll", "Bud", "The Committee (Botanical)", "Sir Stemsley"]
    readonly property var _lore: ["Small and content, mostly.", "Turns light into opinions.",
        "Would like more sun, thanks.", "A day you showed up, in leaf form.", "Rooted, which is enough.",
        "The wobble is just weather."]
    readonly property string displayName: _names[Math.abs(seed) % _names.length]
    readonly property string lore: _lore[Math.abs(Math.floor(seed / 7)) % _lore.length]
    readonly property bool speaking: bubble.opacity > 0.05

    // Palette (green plant + terracotta pot + the icon's cream eyes / warm flower).
    readonly property color cPot: "#B5652D"
    readonly property color cPotD: "#78421E"
    readonly property color cSoil: "#4A3422"
    readonly property color cStem: "#3A6E2C"
    readonly property color cLeaf: "#5FAA46"
    readonly property color cHead: "#4E943A"
    readonly property color cHeadD: "#366828"
    readonly property color cEye: "#F6EFDD"
    readonly property color cPupil: "#1A1C26"
    readonly property color cFlow: "#F2C85C"
    readonly property color cFlowC: "#E1A42C"

    property var px: safePixels(seed)
    property real cell: field.width / px.N

    property real tt: 0
    property real eyeOpen: 1.0
    property real pokeWob: 0            // extra sway kick from a poke, decays via animation
    property bool looking: false
    property int pokes: (memory && memory.pokes) ? memory.pokes : 0
    // Rarer sprouts arrive already in flower; commoner ones bloom as a 30-poke secret.
    readonly property bool bloomed: rarity === "rare" || rarity === "mythic" || pokes >= 30

    readonly property real swayA: (looking ? 0 : Math.sin(tt * 1.1) * 3.2) + pokeWob
    readonly property real idleGazeDown: (Math.sin(tt * 0.5) > 0.6) ? 1 : 0

    NumberAnimation on tt {
        from: 0; to: 6.2831853; duration: 5200
        loops: Animation.Infinite; running: root.lodLevel < 2
    }

    // ---- Pixel generation (Qt-5.6-safe: no Math.imul) ---------------------------------------
    function rngFromSeed(s) {
        var state = (s >>> 0) % 2147483647;
        if (state <= 0) state += 2147483646;
        return function () { state = (state * 16807) % 2147483647; return (state - 1) / 2147483646; };
    }
    function safePixels(sd) { try { return buildPixels(sd); } catch (e) { return defaultPixels(); } }

    function buildPixels(sd) {
        var r = rngFromSeed(sd);
        function ri(a, b) { return a + Math.floor(r() * (b - a + 1)); }
        var N = 16, cx = 8;
        var pot = [], plant = [], flower = [], eyes = [];

        // Pot (static base).
        for (var y = 12; y < 16; y++) {
            var half = (y < 15) ? 4 : 3;
            for (var x = cx - half; x < cx + half; x++) {
                var edge = (x === cx - half || x === cx + half - 1 || y === 15);
                pot.push({ x: x, y: y, c: edge ? cPotD : cPot });
            }
        }
        for (var xs = cx - 4; xs < cx + 4; xs++) pot.push({ x: xs, y: 12, c: cSoil });

        // Genome: head size, plant height, lean, leaves.
        var headH = ri(3, 4), headW = ri(2, 3), stemTop = ri(2, 4);
        var curve = [-1, 0, 0, 1][Math.floor(r() * 4)];
        var headBy = stemTop + headH;
        function stemx(y) { return cx + ((y < 8) ? curve : 0); }

        // Stem.
        for (var ys = headBy; ys < 12; ys++) {
            var sx = stemx(ys);
            plant.push({ x: sx, y: ys, c: cStem });
            if (r() < 0.25) plant.push({ x: sx + 1, y: ys, c: cStem });
        }
        // Leaves (1..3, alternating sides at seeded heights).
        var nleaves = ri(1, 3), used = {};
        for (var i = 0; i < nleaves; i++) {
            var ly = ri(headBy + 1, 11);
            if (used[ly]) continue;
            used[ly] = true;
            var side = (i % 2 === 0) ? 1 : -1;
            if (r() < 0.5) side = -side;
            var base = stemx(ly), len = ri(2, 3);
            for (var k = 1; k <= len; k++) plant.push({ x: base + side * k, y: ly, c: cLeaf });
            plant.push({ x: base + side, y: ly - 1, c: cLeaf });
        }
        // Head (rounded green top that holds the eyes).
        for (var yh = stemTop; yh < headBy; yh++)
            for (var xh = cx - headW; xh <= cx + headW; xh++) {
                var e2 = (xh === cx - headW || xh === cx + headW);
                plant.push({ x: xh, y: yh, c: e2 ? cHeadD : cHead });
            }
        // Eyes (positions; drawn separately so they blink and gaze).
        var ey = stemTop + ((headH >= 4) ? 1 : 0);
        var cols = (headW >= 2) ? [cx - 1, cx + 1] : [cx];
        for (var e = 0; e < cols.length; e++) eyes.push({ gx: cols[e] });
        // Flower crown (the bloom).
        var fy = stemTop - 1;
        flower.push({ x: cx, y: fy, c: cFlowC });
        flower.push({ x: cx - 1, y: fy, c: cFlow }); flower.push({ x: cx + 1, y: fy, c: cFlow });
        flower.push({ x: cx, y: fy - 1, c: cFlow });
        flower.push({ x: cx - 1, y: fy - 1, c: cFlow }); flower.push({ x: cx + 1, y: fy - 1, c: cFlow });

        return { N: N, pot: pot, plant: plant, eyes: eyes, flower: flower, eyeY: ey, potTopY: 12,
                 blinkMs: Math.floor(2800 + r() * 4200) };
    }
    function defaultPixels() {
        return { N: 16, potTopY: 12, eyeY: 4, blinkMs: 3500,
                 pot: [{ x: 6, y: 14, c: cPot }, { x: 7, y: 14, c: cPot }, { x: 8, y: 14, c: cPot }, { x: 9, y: 14, c: cPot }],
                 plant: [{ x: 7, y: 6, c: cHead }, { x: 8, y: 6, c: cHead }, { x: 7, y: 7, c: cStem }],
                 eyes: [{ gx: 7 }], flower: [{ x: 7, y: 5, c: cFlow }] };
    }

    // ---- Behaviour --------------------------------------------------------------------------
    function react() {
        if (root.lodLevel >= 2) return;
        wobbleAnim.restart();
        bubble.say = root._quips[Math.floor(Math.random() * root._quips.length)];
        bubbleAnim.restart();
    }
    function speak() {
        if (root.lodLevel >= 2) return;
        bubble.say = (root.voice && root.voice.length > 0 && Math.random() < 0.22)
                     ? root.voice.toUpperCase() + "!"
                     : root._words[Math.floor(Math.random() * root._words.length)];
        bubbleAnim.restart();
        speakTimer.interval = 3600 + Math.floor(Math.random() * 8000);
    }
    function poke() {
        wobbleAnim.restart();
        wideAnim.restart();
        var m = root.memory || {};
        m.pokes = (m.pokes || 0) + 1;
        root.memory = m;
        root.pokes = m.pokes;
        root.persist(m);
        if (Math.random() < 0.6) speak();
    }

    // ---- Drawing ----------------------------------------------------------------------------
    Item {
        id: field
        width: Math.min(root.width, root.height)
        height: width
        anchors.centerIn: parent

        // Pot: fixed, the plant sways above it.
        Repeater {
            model: px.pot
            delegate: Rectangle {
                x: Math.round(modelData.x * root.cell); y: Math.round(modelData.y * root.cell)
                width: Math.ceil(root.cell) + 1; height: Math.ceil(root.cell) + 1
                color: modelData.c; antialiasing: false
            }
        }

        // Everything above the soil sways around the pot rim.
        Item {
            id: plant
            anchors.fill: parent
            transform: Rotation {
                origin.x: field.width / 2; origin.y: px.potTopY * root.cell
                angle: root.swayA
            }

            Repeater {
                model: px.plant
                delegate: Rectangle {
                    x: Math.round(modelData.x * root.cell); y: Math.round(modelData.y * root.cell)
                    width: Math.ceil(root.cell) + 1; height: Math.ceil(root.cell) + 1
                    color: modelData.c; antialiasing: false
                }
            }

            // The flower (rarity flourish / poke secret).
            Repeater {
                model: px.flower
                delegate: Rectangle {
                    visible: root.bloomed
                    x: Math.round(modelData.x * root.cell); y: Math.round(modelData.y * root.cell)
                    width: Math.ceil(root.cell) + 1; height: Math.ceil(root.cell) + 1
                    color: modelData.c; antialiasing: false
                    scale: root.bloomed ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                }
            }

            // Eyes: cream, 1 wide and 2 tall, blinking; a dark pupil that drifts / looks down.
            Repeater {
                model: px.eyes
                delegate: Item {
                    x: Math.round(modelData.gx * root.cell); y: Math.round(px.eyeY * root.cell)
                    Rectangle {
                        width: root.cell; height: root.cell * 2 * root.eyeOpen
                        y: root.cell * 2 * (1 - root.eyeOpen) / 2
                        color: root.cEye; antialiasing: false
                    }
                    Rectangle {
                        visible: root.eyeOpen > 0.4
                        width: root.cell; height: root.cell
                        y: root.cell * root.idleGazeDown
                        color: root.cPupil; antialiasing: false
                    }
                }
            }
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.poke() }

    // ---- Speech bubble ----------------------------------------------------------------------
    Rectangle {
        id: bubble
        property string say: ""
        property real fs: Math.max(24, Math.min(40, field.width * 0.12))
        color: "#E8E8E8"; radius: height * 0.32
        width: bubbleLabel.implicitWidth + bubble.fs
        height: bubbleLabel.implicitHeight + bubble.fs * 0.5
        x: field.x + field.width * 0.52 - width / 2
        y: field.y + field.height * 0.02 - height
        opacity: 0; scale: 0.6; transformOrigin: Item.Bottom
        Text { id: bubbleLabel; anchors.centerIn: parent; text: bubble.say
               color: "#111318"; font.pixelSize: bubble.fs; font.bold: true }
    }

    // ---- Animations -------------------------------------------------------------------------
    SequentialAnimation {
        id: wobbleAnim
        NumberAnimation { target: root; property: "pokeWob"; to: 10; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "pokeWob"; to: 0; duration: 520
                          easing.type: Easing.OutElastic; easing.amplitude: 1.4 }
    }
    SequentialAnimation {
        id: wideAnim
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.3; duration: 90 }
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.0; duration: 240; easing.type: Easing.OutBack }
    }
    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: root; property: "eyeOpen"; to: 0.06; duration: 60 }
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.0; duration: 120 }
    }
    SequentialAnimation {
        id: bubbleAnim
        ParallelAnimation {
            NumberAnimation { target: bubble; property: "opacity"; to: 1.0; duration: 150 }
            NumberAnimation { target: bubble; property: "scale"; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 3 }
        }
        PauseAnimation { duration: 1300 }
        ParallelAnimation {
            NumberAnimation { target: bubble; property: "opacity"; to: 0.0; duration: 240 }
            NumberAnimation { target: bubble; property: "scale"; to: 0.6; duration: 240 }
        }
    }

    Timer { interval: px.blinkMs; running: root.lodLevel < 2; repeat: true; onTriggered: blinkAnim.restart() }
    Timer { id: speakTimer; interval: 4200 + Math.abs(root.seed % 6000); running: root.lodLevel < 2; repeat: true; onTriggered: root.speak() }
}
