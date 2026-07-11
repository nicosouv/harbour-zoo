import QtQuick 2.6

// A cheap, self-cleaning confetti burst. Call fireAt(x, y) to throw a handful of little squares
// that fly up, spin, and fall. Pure QML — no particle system needed. Overlay it on a page and it
// stays out of the way until fired.
Item {
    id: root
    anchors.fill: parent

    // Bright, on-brand-ish confetti colours (the blobs are grey; the party isn't).
    property var colors: ["#F2C85C", "#2A9D8F", "#E1A42C", "#F6EFDD", "#E86A5C", "#7CB2D9"]

    Component {
        id: piece
        Rectangle {
            id: c
            property real ang: 0
            property real dist: 100
            property int dur: 1300
            width: 8 + Math.random() * 12
            height: 7 + Math.random() * 12
            radius: 1
            antialiasing: false
            rotation: Math.random() * 360
            ParallelAnimation {
                running: true
                NumberAnimation { target: c; property: "x"; to: c.x + Math.cos(c.ang) * c.dist
                    duration: c.dur; easing.type: Easing.OutQuad }
                NumberAnimation { target: c; property: "y"; to: c.y + Math.sin(c.ang) * c.dist + 320
                    duration: c.dur; easing.type: Easing.InQuad }
                NumberAnimation { target: c; property: "opacity"; from: 1; to: 0
                    duration: c.dur; easing.type: Easing.InQuad }
                RotationAnimation { target: c; to: c.rotation + 540 + Math.random() * 540; duration: c.dur }
                onStopped: c.destroy()
            }
        }
    }

    // A big, generous burst: lots of pieces, wide spread, a good long flight.
    function fireAt(px, py) {
        for (var i = 0; i < 70; i++) {
            // Full upward fan, like a properly overfilled party popper.
            var ang = -Math.PI / 2 + (Math.random() - 0.5) * Math.PI * 1.7;
            piece.createObject(root, {
                x: px, y: py,
                color: root.colors[Math.floor(Math.random() * root.colors.length)],
                ang: ang,
                dist: 120 + Math.random() * 320,
                dur: 1100 + Math.random() * 800
            });
        }
    }
}
