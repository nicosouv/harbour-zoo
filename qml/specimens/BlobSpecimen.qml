import QtQuick 2.6

// The hero specimen. A living blob rendered procedurally from the seed — an SDF-metaball body on
// the GPU, reactive googly eyes, spring jiggle on poke. No two are alike: the seed is read as a
// "genome" (see docs/specimen-taxonomy.md + zoo-specimen skill). Deterministic: same seed+rarity
// always yields the same creature. Qt 5.6 / GLSL ES 1.00 compatible (no QtQuick.Shapes).
Specimen {
    id: root

    // Local palette (icon-canonical), kept self-contained so the specimen has no outside deps.
    readonly property color creamColor: "#F6EFDD"
    readonly property color pupilColor: "#1A1C26"

    // A name to occasionally shout in a speech bubble. Empty => a goofy noise instead.
    property string voice: ""
    readonly property var _shouts: ["Oi.", "hello", "BLEP", "mate", "...why", "hm.", "oh good, you",
        "brilliant", "sup", "we meet again"]

    // The genome — a pure function of (seed, rarity). Rebinds when either changes.
    property var g: buildGenome(seed, rarity)

    // Animation clock (0..2π, seamless loop). Drives wobble + idle gaze. Paused for thumbnails.
    property real tt: 0

    // Eye openness (1 = open). Blink and poke-widen animate this.
    property real eyeOpen: 1.0

    // Gaze: follow the finger while pressed, otherwise a gentle idle wander.
    property bool looking: false
    property real touchX: 0
    property real touchY: 0
    readonly property real gazeX: looking ? touchX : 0.35 * Math.sin(tt * 0.7)
    readonly property real gazeY: looking ? touchY : 0.22 * Math.sin(tt * 0.9 + 1.0)

    // Sample flavor (until StaticFlavorProvider wires in): stable per seed.
    readonly property var _names: ["Sir Reginald Ooze", "Beans", "The Understudy", "Gerald, Probably",
        "Small Cousin", "The Committee", "Blob Ross", "Modest Steve", "Uncertain Todd",
        "Professor Squish", "Nap Enthusiast", "The Damp One"]
    readonly property var _lore: ["A blob that is understood.", "The wobble is the whole idea.",
        "Mostly still, occasionally delighted.", "Small and content beats large and worried.",
        "Here, which is enough.", "Came for the crumbs, stayed for the vibe."]
    readonly property string displayName: _names[Math.abs(seed) % _names.length]
    readonly property string lore: _lore[Math.abs(Math.floor(seed / 7)) % _lore.length]

    NumberAnimation on tt {
        from: 0; to: 6.2831853; duration: 5000
        loops: Animation.Infinite; running: root.lodLevel < 2
    }

    // ---- Genome construction (deterministic, seed-driven) -----------------------------------
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

        var lobeCount = 2 + Math.floor(r() * 3.999);   // 2..5 lobes
        var lobes = [];
        var baseR = range(0.20, 0.30);
        for (var i = 0; i < 5; ++i) {
            if (i < lobeCount) {
                var ang = r() * Math.PI * 2;
                var dist = range(0.0, 0.14);
                lobes.push(Qt.vector3d(Math.cos(ang) * dist, Math.sin(ang) * dist,
                                       baseR * range(0.7, 1.15)));
            } else {
                lobes.push(Qt.vector3d(10, 10, 0)); // inactive: far away, zero radius => ignored
            }
        }

        var eyeCount = pick([1, 2, 2, 2, 3]); // usually two
        var eyes = [];
        var spacing = range(0.13, 0.21);
        var eyeY = range(-0.06, 0.03);
        var eyeSize = range(0.17, 0.26);
        if (eyeCount === 1) {
            eyes.push({ x: 0, y: eyeY, s: eyeSize * 1.25 });
        } else if (eyeCount === 2) {
            eyes.push({ x: -spacing, y: eyeY, s: eyeSize });
            eyes.push({ x: spacing, y: eyeY + range(-0.02, 0.02), s: eyeSize });
        } else {
            eyes.push({ x: -spacing, y: eyeY, s: eyeSize * 0.8 });
            eyes.push({ x: 0, y: eyeY - 0.04, s: eyeSize * 0.8 });
            eyes.push({ x: spacing, y: eyeY, s: eyeSize * 0.8 });
        }

        // Body colour: common stays near the icon ink; rarer widens the hue range.
        var wander = (rarity === "common") ? 0.04 : (rarity === "uncommon" ? 0.12 : 0.5);
        var h = (0.625 + range(-wander, wander) + 1) % 1;   // 0.625 ≈ icon navy hue
        var sat = (rarity === "common") ? range(0.14, 0.24) : range(0.35, 0.70);
        var lig = range(0.16, 0.26);

        // Eye shape genes — eyes are NOT necessarily round. aspect >1 = wide/sleepy, <1 = tall;
        // corner 0.5 = fully round/pill, lower = boxy/almond; tilt slants them; pupils vary too.
        var eyeAspect = range(0.72, 1.7);
        var eyeCorner = range(0.16, 0.5);
        var eyeTilt = Math.floor(range(0, 24));

        return {
            lobes: lobes,
            eyes: eyes,
            eyeAspect: eyeAspect,
            eyeCorner: eyeCorner,
            eyeTilt: eyeTilt,
            mirrorTilt: (r() < 0.85),          // usually the pair slants symmetrically
            pupilRatio: range(0.34, 0.46),
            pupilAspect: range(0.62, 1.18),
            pupilCorner: range(0.30, 0.5),
            blinkMs: Math.floor(range(2600, 6000)),
            wobbleAmp: range(0.010, 0.026),
            wobbleFreq: range(3.0, 7.0),
            body: Qt.hsla(h, sat, lig, 1),
            accent: Qt.hsla((h + 0.5) % 1, 0.6, 0.55, 1),
            temperament: pick(["shy", "hyper", "sleepy", "smug", "nervous", "zen"])
        };
    }

    // ---- Interaction ------------------------------------------------------------------------
    function poke() {
        pokeAnim.restart();
        wideAnim.restart();
        var m = root.memory || {};
        m.pokes = (m.pokes || 0) + 1;
        root.memory = m;
        root.persist(m);
        if (m.pokes % 50 === 0)
            puffAnim.restart(); // secret: every 50 pokes it burps
        else if (Math.random() < 0.5)
            shout();            // poking it is rude; it may comment
    }

    // Occasional goofy outburst — shouts the player's name, or a noise if there isn't one.
    function shout() {
        if (root.lodLevel >= 2)
            return;
        bubble.say = (root.voice && root.voice.length > 0)
                     ? root.voice.toUpperCase() + "!"
                     : root._shouts[Math.floor(Math.random() * root._shouts.length)];
        bubbleAnim.restart();
    }

    // ---- Drawing ----------------------------------------------------------------------------
    Item {
        id: field
        width: Math.min(root.width, root.height)
        height: width
        anchors.centerIn: parent
        transformOrigin: Item.Center

        // Body: SDF-metaball union, domain-warped for organic wobble, on the GPU.
        ShaderEffect {
            id: body
            anchors.fill: parent

            property vector3d b0: g.lobes[0]
            property vector3d b1: g.lobes[1]
            property vector3d b2: g.lobes[2]
            property vector3d b3: g.lobes[3]
            property vector3d b4: g.lobes[4]
            property real uT: root.tt
            property real uAmp: g.wobbleAmp
            property real uFreq: g.wobbleFreq
            property color uBody: g.body
            property color uAccent: g.accent
            property real uEdge: 0.012
            property real uIri: (root.rarity === "rare" || root.rarity === "mythic") ? 1.0 : 0.0
            property real uGlow: (root.rarity === "mythic") ? 1.0 : 0.0

            fragmentShader: "
                uniform lowp float qt_Opacity;
                varying highp vec2 qt_TexCoord0;
                uniform highp vec3 b0; uniform highp vec3 b1; uniform highp vec3 b2;
                uniform highp vec3 b3; uniform highp vec3 b4;
                uniform highp float uT; uniform highp float uAmp; uniform highp float uFreq;
                uniform lowp vec4 uBody; uniform lowp vec4 uAccent;
                uniform highp float uEdge; uniform lowp float uIri; uniform lowp float uGlow;

                highp float sdCircle(highp vec2 p, highp vec3 c) { return length(p - c.xy) - c.z; }
                highp float smin(highp float a, highp float b, highp float k) {
                    highp float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
                    return mix(b, a, h) - k * h * (1.0 - h);
                }
                void main() {
                    highp vec2 p = qt_TexCoord0 - vec2(0.5);
                    // organic domain warp (seamless: t appears only inside sin(.. + t) / sin(.. - t))
                    p += uAmp * vec2(sin(p.y * uFreq + uT) + 0.5 * sin(p.x * uFreq * 1.7 - uT),
                                     sin(p.x * uFreq + uT) + 0.5 * sin(p.y * uFreq * 1.7 - uT));
                    highp float k = 0.08;
                    highp float d = sdCircle(p, b0);
                    d = smin(d, sdCircle(p, b1), k);
                    d = smin(d, sdCircle(p, b2), k);
                    d = smin(d, sdCircle(p, b3), k);
                    d = smin(d, sdCircle(p, b4), k);

                    highp float a = 1.0 - smoothstep(-uEdge, uEdge, d);

                    lowp vec3 col = uBody.rgb;
                    highp float hi = clamp(1.0 - length(p - vec2(-0.14, -0.16)) * 1.3, 0.0, 1.0);
                    col += hi * 0.10;                        // soft top-left highlight
                    col -= clamp(p.y, 0.0, 0.5) * 0.10;       // gentle bottom shade (volume)
                    if (uIri > 0.5) {                         // rare iridescence
                        lowp vec3 iri = 0.5 + 0.5 * cos(6.2831 * (p.x + p.y + uT * 0.05)
                                                        + vec3(0.0, 2.0, 4.0));
                        col = mix(col, iri, 0.30);
                    }
                    lowp float glow = uGlow * (1.0 - smoothstep(uEdge, uEdge + 0.06, d)) * 0.5;
                    col += uAccent.rgb * glow;                // mythic outer glow
                    a = max(a, glow);

                    gl_FragColor = vec4(col * a, a) * qt_Opacity;
                }"
        }

        // Eyes: the soul. Shaped by the genome (not necessarily round): aspect, roundedness and
        // tilt vary. They track the finger, blink, and widen on poke.
        Repeater {
            model: g.eyes
            delegate: Item {
                id: eye
                property var e: modelData
                property real base: field.width * e.s
                property real ew: base * g.eyeAspect          // eye width
                property real eh: base / g.eyeAspect           // eye height (tall/short = not round)
                width: ew
                height: eh
                x: field.width * (0.5 + e.x) - ew / 2
                y: field.height * (0.5 + e.y) - eh / 2
                // slant: pair mirrors around the centre eye; a single/centre eye stays level
                rotation: g.eyeTilt * (g.mirrorTilt ? (e.x < 0 ? -1 : (e.x > 0 ? 1 : 0)) : 1)
                transformOrigin: Item.Center

                Rectangle { // white — blink squashes height only
                    width: eye.ew
                    height: eye.eh * root.eyeOpen
                    anchors.centerIn: parent
                    radius: Math.min(width, height) * g.eyeCorner
                    color: root.creamColor
                }
                Rectangle { // pupil — shaped, gaze-tracking
                    id: pupil
                    property real pw: Math.min(eye.ew, eye.eh) * g.pupilRatio
                    width: pw * g.pupilAspect
                    height: pw / g.pupilAspect
                    radius: Math.min(width, height) * g.pupilCorner
                    color: root.pupilColor
                    visible: root.eyeOpen > 0.35
                    x: eye.ew * 0.5 - width / 2 + root.gazeX * eye.ew * 0.16
                    y: eye.eh * 0.5 - height / 2 + root.gazeY * eye.eh * 0.16
                    Rectangle { // catch-light
                        width: parent.width * 0.30; height: parent.height * 0.30
                        radius: Math.min(width, height) / 2
                        color: root.creamColor
                        x: parent.width * 0.18; y: parent.height * 0.16
                    }
                }
            }
        }

        // Burp puff (the 50-poke secret).
        Rectangle {
            id: puff
            anchors.centerIn: parent
            width: field.width * 0.2; height: width; radius: width / 2
            color: g.accent
            opacity: 0
            scale: 0.4
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

    // ---- Animations -------------------------------------------------------------------------
    SequentialAnimation {
        id: pokeAnim
        NumberAnimation { target: field; property: "scale"; to: 0.86; duration: 90
            easing.type: Easing.OutQuad }
        NumberAnimation { target: field; property: "scale"; to: 1.0; duration: 480
            easing.type: Easing.OutBack; easing.overshoot: 2.4 }
    }
    SequentialAnimation {
        id: wideAnim
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.3; duration: 90 }
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.0; duration: 260
            easing.type: Easing.OutBack }
    }
    SequentialAnimation {
        id: blinkAnim
        NumberAnimation { target: root; property: "eyeOpen"; to: 0.08; duration: 70
            easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "eyeOpen"; to: 1.0; duration: 110
            easing.type: Easing.OutQuad }
    }
    SequentialAnimation {
        id: puffAnim
        ParallelAnimation {
            NumberAnimation { target: puff; property: "opacity"; from: 0.7; to: 0; duration: 600 }
            NumberAnimation { target: puff; property: "scale"; from: 0.4; to: 1.6; duration: 600
                easing.type: Easing.OutQuad }
        }
    }

    Timer {
        interval: g.blinkMs
        running: root.lodLevel < 2
        repeat: true
        onTriggered: blinkAnim.restart()
    }

    // Speech bubble (sits just over the blob's head so it doesn't overrun the layout).
    Rectangle {
        id: bubble
        property string say: ""
        color: root.creamColor
        radius: height * 0.34
        width: bubbleLabel.implicitWidth + field.width * 0.14
        height: bubbleLabel.implicitHeight + field.width * 0.07
        x: field.x + field.width * 0.5 - width / 2
        y: field.y - height * 0.5
        opacity: 0
        scale: 0.6
        transformOrigin: Item.Bottom

        Text {
            id: bubbleLabel
            anchors.centerIn: parent
            text: bubble.say
            color: root.pupilColor
            font.pixelSize: Math.max(11, field.width * 0.11)
            font.bold: true
        }
        Rectangle { // little tail
            width: field.width * 0.06; height: width
            color: root.creamColor
            rotation: 45
            x: bubble.width * 0.5 - width / 2
            y: bubble.height - height / 2
        }
    }
    SequentialAnimation {
        id: bubbleAnim
        ParallelAnimation {
            NumberAnimation { target: bubble; property: "opacity"; to: 1.0; duration: 160 }
            NumberAnimation { target: bubble; property: "scale"; to: 1.0; duration: 240
                easing.type: Easing.OutBack; easing.overshoot: 3.0 }
        }
        PauseAnimation { duration: 1500 }
        ParallelAnimation {
            NumberAnimation { target: bubble; property: "opacity"; to: 0.0; duration: 260 }
            NumberAnimation { target: bubble; property: "scale"; to: 0.6; duration: 260 }
        }
    }
    Timer { // random-ish outbursts
        interval: 6000 + Math.abs(root.seed % 9000)
        running: root.lodLevel < 2
        repeat: true
        onTriggered: shout()
    }
}
