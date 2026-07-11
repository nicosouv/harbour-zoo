import QtQuick 2.6

// The hero specimen: a crisp PIXEL-ART blob generated from the seed. Grayscale / black tones, a
// small footprint, a gentle little hop, blinking eyes that track your finger, and the odd muttered
// word. Pure QML squares (no shader, no smoothing) => renders identically on every device, and is
// deterministic: same seed => same creature, forever.
Specimen {
    id: root

    readonly property color pupilColor: "#111318"
    readonly property color eyeColor: "#E8E8E8"

    property string voice: ""
    readonly property var _words: ["blep", "boing", "oi", "hm", "meep", "wot", "hello", "?!",
        "...", "nyoom", "ok", "ee", "hi", "brb", "oof", "mrr"]

    // Pixel plan built from the seed (silhouette cells + eye positions). Never throws => never blank.
    property var px: safePixels(seed)
    property real cell: field.width / px.N

    property real tt: 0
    property real hopY: 0
    property real eyeOpen: 1.0
    property bool looking: false
    property real touchX: 0
    property real touchY: 0
    readonly property real gazeX: looking ? touchX : 0.6 * Math.sin(tt * 0.7)
    readonly property real gazeY: looking ? touchY : 0.4 * Math.sin(tt * 0.9 + 1.0)
    readonly property real idleBob: Math.sin(tt * 1.6) * (field.height * 0.008)

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

    // ---- Pixel generation (Qt-5.6-safe: no Math.imul) ---------------------------------------
    function rngFromSeed(s) {
        var state = (s >>> 0) % 2147483647;
        if (state <= 0) state += 2147483646;
        return function () { state = (state * 16807) % 2147483647; return (state - 1) / 2147483646; };
    }
    function grayHex(v) {
        v = Math.max(0, Math.min(1, v));
        var n = Math.round(v * 255);
        var h = n.toString(16); if (h.length < 2) h = "0" + h;
        return "#" + h + h + h;
    }
    function safePixels(seed) { try { return buildPixels(seed); } catch (e) { return defaultPixels(); } }

    function buildPixels(seed) {
        var r = rngFromSeed(seed);
        function range(a, b) { return a + (b - a) * r(); }
        var N = 12;
        var rx = range(0.30, 0.40), ry = range(0.34, 0.46);
        var on = [];
        for (var y = 0; y < N; y++) {
            on[y] = [];
            for (var x = 0; x < N; x++) {
                var nx = (x + 0.5) / N - 0.5, ny = (y + 0.5) / N - 0.5;
                on[y][x] = ((nx * nx) / (rx * rx) + (ny * ny) / (ry * ry)) <= 1.0;
            }
        }
        var topL = range(0.40, 0.52), botL = range(0.16, 0.24);
        var cells = [];
        for (var yy = 0; yy < N; yy++) {
            for (var xx = 0; xx < N; xx++) {
                if (!on[yy][xx]) continue;
                var edge = (xx === 0 || !on[yy][xx - 1]) || (xx === N - 1 || !on[yy][xx + 1])
                        || (yy === 0 || !on[yy - 1][xx]) || (yy === N - 1 || !on[yy + 1][xx]);
                var t = yy / (N - 1);
                var L = topL + (botL - topL) * t;
                var c = edge ? grayHex(0.09) : grayHex(Math.max(0.06, L + (r() < 0.06 ? -0.09 : 0)));
                cells.push({ x: xx, y: yy, c: c });
            }
        }
        var two = r() > 0.2;
        var eyeRow = Math.floor(N * range(0.36, 0.46));
        var eyeCol = Math.floor(N * range(0.24, 0.30));
        var eyes = two ? [{ x: eyeCol, y: eyeRow }, { x: N - 2 - eyeCol, y: eyeRow }]
                       : [{ x: Math.floor(N / 2) - 1, y: eyeRow }];
        return { N: N, cells: cells, eyes: eyes,
                 hopH: range(0.05, 0.10),
                 blinkMs: Math.floor(range(2600, 6000)),
                 hopMinMs: Math.floor(range(1800, 3000)),
                 hopVarMs: Math.floor(range(2000, 4200)) };
    }
    function defaultPixels() {
        var cells = [];
        for (var y = 2; y < 10; y++) for (var x = 3; x < 9; x++) cells.push({ x: x, y: y, c: "#3A3A3A" });
        return { N: 12, cells: cells, eyes: [{ x: 4, y: 4 }, { x: 6, y: 4 }],
                 hopH: 0.07, blinkMs: 3500, hopMinMs: 2200, hopVarMs: 2600 };
    }

    // ---- Behaviour --------------------------------------------------------------------------
    function hop() {
        if (root.lodLevel >= 2) return;
        hopAnim.restart();
        hopTimer.interval = px.hopMinMs + Math.floor(Math.random() * px.hopVarMs);
    }
    function speak() {
        if (root.lodLevel >= 2) return;
        bubble.say = (root.voice && root.voice.length > 0 && Math.random() < 0.22)
                     ? root.voice.toUpperCase() + "!"
                     : root._words[Math.floor(Math.random() * root._words.length)];
        bubbleAnim.restart();
        speakTimer.interval = 3000 + Math.floor(Math.random() * 8000);
    }
    function poke() {
        hopAnim.restart();
        wideAnim.restart();
        var m = root.memory || {};
        m.pokes = (m.pokes || 0) + 1;
        root.memory = m;
        root.persist(m);
        if (Math.random() < 0.6) speak();
    }

    // ---- Drawing (crisp squares) ------------------------------------------------------------
    Item {
        id: field
        width: Math.min(root.width, root.height)
        height: width
        anchors.centerIn: parent

        Item {
            id: visual
            anchors.fill: parent
            transform: Translate { y: root.hopY + root.idleBob }

            // Ground shadow (shrinks as it lifts).
            Rectangle {
                width: field.width * (0.42 + root.hopY / field.height * 0.5)
                height: root.cell * 0.8
                radius: height / 2
                color: "#000000"; opacity: 0.20
                x: field.width / 2 - width / 2
                y: field.height * 0.92
            }

            // Body pixels.
            Repeater {
                model: px.cells
                delegate: Rectangle {
                    x: Math.round(modelData.x * root.cell)
                    y: Math.round(modelData.y * root.cell)
                    width: Math.ceil(root.cell) + 1
                    height: Math.ceil(root.cell) + 1
                    color: modelData.c
                    antialiasing: false
                }
            }

            // Eyes: a 2×2 light block + a 1px pupil that blinks and tracks.
            Repeater {
                model: px.eyes
                delegate: Item {
                    x: Math.round(modelData.x * root.cell)
                    y: Math.round(modelData.y * root.cell)
                    Rectangle {
                        width: root.cell * 2
                        height: root.cell * 2 * root.eyeOpen
                        y: root.cell * (1 - root.eyeOpen)
                        color: root.eyeColor
                        antialiasing: false
                    }
                    Rectangle {
                        width: root.cell; height: root.cell
                        color: root.pupilColor
                        antialiasing: false
                        visible: root.eyeOpen > 0.4
                        x: root.cell * 0.5 + root.gazeX * root.cell * 0.5
                        y: root.cell * 0.5 + root.gazeY * root.cell * 0.5
                    }
                }
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
        var cx = field.x + field.width / 2, cy = field.y + field.height / 2;
        root.touchX = Math.max(-1, Math.min(1, (mouse.x - cx) / (field.width / 2)));
        root.touchY = Math.max(-1, Math.min(1, (mouse.y - cy) / (field.height / 2)));
    }

    // ---- Speech bubble ----------------------------------------------------------------------
    Rectangle {
        id: bubble
        property string say: ""
        color: "#E8E8E8"; radius: height * 0.3
        width: bubbleLabel.implicitWidth + field.width * 0.12
        height: bubbleLabel.implicitHeight + field.width * 0.06
        x: field.x + field.width * 0.5 - width / 2
        y: field.y + field.height * 0.06 - height
        opacity: 0; scale: 0.6; transformOrigin: Item.Bottom
        Text { id: bubbleLabel; anchors.centerIn: parent; text: bubble.say
               color: "#111318"; font.pixelSize: Math.max(11, field.width * 0.11); font.bold: true }
    }

    // ---- Animations (gentle, low hop) -------------------------------------------------------
    SequentialAnimation {
        id: hopAnim
        NumberAnimation { target: root; property: "hopY"; to: -field.height * (px ? px.hopH : 0.07)
            duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "hopY"; to: 0; duration: 200; easing.type: Easing.InQuad }
    }
    SequentialAnimation {
        id: wideAnim
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.3; duration: 90 }
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.0; duration: 240; easing.type: Easing.OutBack }
    }
    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: root; property: "eyeOpen"; to: 0.06; duration: 60 }
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.0; duration: 110 }
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
    Timer { id: hopTimer; interval: px.hopMinMs; running: root.lodLevel < 2; repeat: true; onTriggered: root.hop() }
    Timer { id: speakTimer; interval: 3500 + Math.abs(root.seed % 6000); running: root.lodLevel < 2; repeat: true; onTriggered: root.speak() }
}
