import QtQuick 2.6

// A cheap, self-cleaning confetti burst. Call fireAt(x, y) to throw a handful of little squares
// that POP UP, spin, and fall back down. Pure QML — no particle system needed. Overlay it on a
// page and it stays out of the way until fired.
Item {
    id: root
    anchors.fill: parent

    // Bright, on-brand-ish confetti colours (the blobs are grey; the party isn't).
    property var colors: ["#F2C85C", "#2A9D8F", "#E1A42C", "#F6EFDD", "#E86A5C", "#7CB2D9"]

    Component {
        id: piece
        Rectangle {
            id: c
            property real x0: 0        // captured start point, so the arc's targets don't chase y
            property real y0: 0
            property real vx: 0        // horizontal drift (both sides)
            property real rise: 220    // how high it pops before gravity wins
            property real drop: 520    // how far it falls after the peak (ends below the start)
            property int dur: 1300
            width: 8 + Math.random() * 12
            height: 7 + Math.random() * 12
            radius: 1
            antialiasing: false
            rotation: Math.random() * 360
            Component.onCompleted: { x0 = x; y0 = y }
            ParallelAnimation {
                running: true
                NumberAnimation { target: c; property: "x"; to: c.x0 + c.vx
                    duration: c.dur; easing.type: Easing.OutQuad }
                // Up to a peak (decelerating), then down past the start (accelerating): a real arc.
                SequentialAnimation {
                    NumberAnimation { target: c; property: "y"; to: c.y0 - c.rise
                        duration: c.dur * 0.42; easing.type: Easing.OutQuad }
                    NumberAnimation { target: c; property: "y"; to: c.y0 - c.rise + c.drop
                        duration: c.dur * 0.58; easing.type: Easing.InQuad }
                }
                NumberAnimation { target: c; property: "opacity"; from: 1; to: 0
                    duration: c.dur; easing.type: Easing.InQuad }
                RotationAnimation { target: c; to: c.rotation + 540 + Math.random() * 540; duration: c.dur }
                onStopped: c.destroy()
            }
        }
    }

    // A big, generous burst: lots of pieces that leap up and rain back down.
    function fireAt(px, py) {
        for (var i = 0; i < 70; i++) {
            piece.createObject(root, {
                x: px, y: py,
                color: root.colors[Math.floor(Math.random() * root.colors.length)],
                vx: (Math.random() - 0.5) * 2 * (60 + Math.random() * 170),
                rise: 200 + Math.random() * 280,
                drop: 440 + Math.random() * 260,
                dur: 1200 + Math.random() * 800
            });
        }
    }
}
