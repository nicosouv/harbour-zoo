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
            width: 6 + Math.random() * 6
            height: 5 + Math.random() * 6
            radius: 1
            antialiasing: false
            rotation: Math.random() * 360
            ParallelAnimation {
                running: true
                NumberAnimation { target: c; property: "x"; to: c.x + Math.cos(c.ang) * c.dist
                    duration: 950; easing.type: Easing.OutQuad }
                NumberAnimation { target: c; property: "y"; to: c.y + Math.sin(c.ang) * c.dist + 160
                    duration: 950; easing.type: Easing.InQuad }
                NumberAnimation { target: c; property: "opacity"; from: 1; to: 0; duration: 950 }
                RotationAnimation { target: c; to: c.rotation + 360 + Math.random() * 360; duration: 950 }
                onStopped: c.destroy()
            }
        }
    }

    function fireAt(px, py) {
        for (var i = 0; i < 22; i++) {
            // Mostly upward spread, like a popped party popper.
            var ang = -Math.PI / 2 + (Math.random() - 0.5) * Math.PI * 1.3;
            piece.createObject(root, {
                x: px, y: py,
                color: root.colors[Math.floor(Math.random() * root.colors.length)],
                ang: ang, dist: 70 + Math.random() * 140
            });
        }
    }
}
