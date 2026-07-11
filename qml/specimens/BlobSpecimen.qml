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
    // Weary, sarcastic remarks about existence, muttered when two blobs bump.
    readonly property var _quips: ["excuse you", "we meet again", "personal space?", "oh, it's you",
        "living the dream", "another day, another shuffle", "thrilling", "peak existence, this",
        "watch it", "cosy", "hello again, apparently", "delightful", "can't wait to do this forever",
        "mind the paint", "such is life"]

    // "" or "mix" => style comes from the seed; a specific style id forces every blob to it.
    property string styleOverride: ""
    // Pixel plan built from the seed (silhouette cells + eye positions). Never throws => never blank.
    property var px: safePixels(seed, styleOverride)
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
    function safePixels(seed, ov) { try { return buildPixels(seed, ov); } catch (e) { return defaultPixels(); } }
    readonly property var _styleIds: ["mono","chonk","ovoid","bean","hires","slime","cyclops","smiley","ghost"]

    // Silhouette helpers.
    function _mask(N, rx, ry, cy, bump, r) {
        var on = [];
        for (var y = 0; y < N; y++) {
            on[y] = [];
            for (var x = 0; x < N; x++) {
                var nx = (x + 0.5) / N - 0.5, ny = (y + 0.5) / N - cy;
                var rr = (nx * nx) / (rx * rx) + (ny * ny) / (ry * ry);
                if (bump) rr += bump * Math.sin(x * 1.7 + y * 0.9) * 0.03;
                on[y][x] = rr <= 1.0;
            }
        }
        return on;
    }
    function _edge(on, x, y, N) {
        if (x <= 0 || !on[y][x - 1]) return true;
        if (x >= N - 1 || !on[y][x + 1]) return true;
        if (y <= 0 || !on[y - 1][x]) return true;
        if (y >= N - 1 || !on[y + 1][x]) return true;
        return false;
    }

    // Each blob's STYLE is drawn from its seed (mix), unless an override forces one style.
    function buildPixels(seed, ov) {
        var r = rngFromSeed(seed);
        function rg(a, b) { return a + (b - a) * r(); }
        function ri(a, b) { return a + Math.floor(r() * (b - a + 1)); }
        // Weighted style pool (mono + chonk favoured).
        var pool = ["mono","mono","mono","chonk","chonk","chonk","ovoid","ovoid",
                    "bean","bean","hires","hires","slime","cyclops","smiley","ghost"];
        var style = pool[Math.floor(r() * pool.length)];
        if (ov && ov !== "mix" && _styleIds.indexOf(ov) >= 0) style = ov;

        var N, on, outline = -1, top = 150, bot = 95, cy = 0.5;
        var mono = false, gloss = false, scallop = false, mouth = false;
        if (style === "mono") { N = 12; on = _mask(N, rg(0.34,0.40), rg(0.40,0.46), cy, 0, r); mono = true; }
        else if (style === "chonk") { N = 14; on = _mask(N, 0.44, 0.44, cy, 0, r); outline = 18; top = 172; bot = 122; }
        else if (style === "ovoid") { N = 12; on = _mask(N, rg(0.34,0.40), rg(0.40,0.46), cy, 0, r); outline = 25; top = rg(145,165); bot = rg(85,100); }
        else if (style === "bean") { N = 13; on = _mask(N, 0.42, 0.30, cy, 1.0, r); outline = 22; }
        else if (style === "hires") { N = 16; on = _mask(N, rg(0.36,0.42), rg(0.42,0.48), cy, 0, r); outline = 30; top = 160; bot = 90; }
        else if (style === "slime") { N = 13; cy = 0.42; on = _mask(N, 0.40, 0.34, cy, 0, r); top = 175; bot = 110; gloss = true; }
        else if (style === "cyclops") { N = 12; on = _mask(N, 0.36, 0.44, cy, 0, r); outline = 22; }
        else if (style === "smiley") { N = 13; on = _mask(N, 0.40, 0.42, cy, 0, r); outline = 22; mouth = true; }
        else { style = "ghost"; N = 13; cy = 0.40; on = _mask(N, 0.36, 0.46, cy, 0, r); outline = 20; scallop = true; }

        if (scallop) for (var sx = 0; sx < N; sx++) if (sx % 3 === 0) for (var sy = N - 2; sy < N; sy++) on[sy][sx] = false;

        var cells = [];
        for (var yy = 0; yy < N; yy++) for (var xx = 0; xx < N; xx++) {
            if (!on[yy][xx]) continue;
            if (mono) { cells.push({ x: xx, y: yy, c: "#282828" }); continue; }
            if (outline >= 0 && _edge(on, xx, yy, N)) { cells.push({ x: xx, y: yy, c: grayHex(outline / 255) }); continue; }
            var t = yy / (N - 1);
            var v = (top + (bot - top) * t) / 255;
            if (r() < 0.05) v -= 0.09;
            cells.push({ x: xx, y: yy, c: grayHex(Math.max(0.06, v)) });
        }
        if (gloss) { if (on[3] && on[3][4]) cells.push({ x: 4, y: 3, c: "#E6E6E6" });
                     if (on[3] && on[3][5]) cells.push({ x: 5, y: 3, c: "#DADADA" }); }
        if (mouth) { for (var mc = 5; mc <= 7; mc++) if (on[8] && on[8][mc]) cells.push({ x: mc, y: 8, c: "#141416" }); }

        // Eye descriptors: { gx, gy, gw, gh, pupil } in grid cells.
        var eyes = [];
        if (style === "cyclops") {
            eyes.push({ gx: 4, gy: 4, gw: 4, gh: 3, pupil: true });
        } else if (style === "chonk") {
            var chy = ri(5, 6), cl = ri(3, 4);
            eyes.push({ gx: cl, gy: chy, gw: 3, gh: 3, pupil: true });
            eyes.push({ gx: N - 3 - cl, gy: chy, gw: 3, gh: 3, pupil: true });
        } else if (style === "bean") {
            var by = ri(5, 6);
            eyes.push({ gx: 4, gy: by, gw: 2, gh: 1, pupil: false });
            eyes.push({ gx: 7, gy: by, gw: 2, gh: 1, pupil: false });
        } else {
            var el = (style === "hires") ? 5 : 3;
            var ey = (style === "hires") ? ri(6, 7) : (style === "slime") ? ri(5, 6) : (style === "smiley") ? 4 : ri(4, 5);
            eyes.push({ gx: el, gy: ey, gw: 2, gh: 2, pupil: !mono });
            eyes.push({ gx: N - 2 - el, gy: ey, gw: 2, gh: 2, pupil: !mono });
        }

        return { N: N, cells: cells, eyes: eyes, style: style,
                 hopH: rg(0.045, 0.085),
                 blinkMs: Math.floor(rg(2600, 6000)),
                 hopMinMs: Math.floor(rg(1800, 3000)),
                 hopVarMs: Math.floor(rg(2000, 4200)) };
    }
    function defaultPixels() {
        var cells = [];
        for (var y = 2; y < 10; y++) for (var x = 3; x < 9; x++) cells.push({ x: x, y: y, c: "#3A3A3A" });
        return { N: 12, cells: cells,
                 eyes: [{ gx: 3, gy: 4, gw: 2, gh: 2, pupil: true }, { gx: 7, gy: 4, gw: 2, gh: 2, pupil: true }],
                 style: "ovoid", hopH: 0.07, blinkMs: 3500, hopMinMs: 2200, hopVarMs: 2600 };
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
    // Bumped into a neighbour: a small hop and a sarcastic remark about life.
    function react() {
        if (root.lodLevel >= 2) return;
        hopAnim.restart();
        bubble.say = root._quips[Math.floor(Math.random() * root._quips.length)];
        bubbleAnim.restart();
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

            // Eyes: sized per style (2×2, 3×3, sleepy line, big cyclops), blinking + gaze-tracking.
            Repeater {
                model: px.eyes
                delegate: Item {
                    property var e: modelData
                    property real ew: e.gw * root.cell
                    property real eh: e.gh * root.cell
                    x: Math.round(e.gx * root.cell)
                    y: Math.round(e.gy * root.cell)
                    Rectangle {   // white
                        width: parent.ew
                        height: parent.eh * root.eyeOpen
                        y: parent.eh * (1 - root.eyeOpen) / 2
                        color: root.eyeColor
                        antialiasing: false
                    }
                    Rectangle {   // pupil
                        visible: e.pupil && root.eyeOpen > 0.4
                        property real psz: (e.gw >= 4 ? 2 : 1) * root.cell
                        width: psz; height: psz
                        color: root.pupilColor
                        antialiasing: false
                        x: (parent.ew - width) / 2 + root.gazeX * (parent.ew - width) / 2
                        y: (parent.eh - height) / 2 + root.gazeY * (parent.eh - height) / 2
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
        // Readable regardless of how small the blob is (enclosure blobs are tiny).
        property real fs: Math.max(24, Math.min(40, field.width * 0.12))
        color: "#E8E8E8"; radius: height * 0.32
        width: bubbleLabel.implicitWidth + bubble.fs
        height: bubbleLabel.implicitHeight + bubble.fs * 0.5
        x: field.x + field.width * 0.5 - width / 2
        y: field.y + field.height * 0.06 - height
        opacity: 0; scale: 0.6; transformOrigin: Item.Bottom
        Text { id: bubbleLabel; anchors.centerIn: parent; text: bubble.say
               color: "#111318"; font.pixelSize: bubble.fs; font.bold: true }
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
