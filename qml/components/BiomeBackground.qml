import QtQuick 2.6

// Pixel-art biome backdrop for the enclosure. Flat colours, hard edges, a few blocky motifs per
// theme. Cheap to render. theme ∈ night | grass | desert | farwest | cyberpunk | snow.
Item {
    id: root
    property string theme: "night"
    readonly property real horizon: 0.64
    readonly property real u: width / 40   // pixel unit
    clip: true

    function skyTop() {
        switch (theme) {
        case "grass": return "#7EC0EE"; case "desert": return "#F4B06A";
        case "farwest": return "#E7A96C"; case "cyberpunk": return "#2A0E3E";
        case "snow": return "#C9D6E5"; default: return "#161A2E";
        }
    }
    function skyBottom() {
        switch (theme) {
        case "grass": return "#C6E9FF"; case "desert": return "#FBE3B8";
        case "farwest": return "#F1D6AC"; case "cyberpunk": return "#0B0416";
        case "snow": return "#EAF2FA"; default: return "#0E1120";
        }
    }
    function ground() {
        switch (theme) {
        case "grass": return "#4E9A3E"; case "desert": return "#D9A85C";
        case "farwest": return "#C99A5B"; case "cyberpunk": return "#12061F";
        case "snow": return "#EDF3F8"; default: return "#181B24";
        }
    }

    // Sky
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.height * root.horizon
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.skyTop() }
            GradientStop { position: 1.0; color: root.skyBottom() }
        }
    }
    // Ground
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root.height * (1 - root.horizon)
        color: root.ground()
    }

    // Stars (night) / neon dots (cyberpunk)
    Repeater {
        model: (theme === "night" || theme === "cyberpunk") ? 14 : 0
        delegate: Rectangle {
            width: root.u * 0.5; height: width
            color: theme === "cyberpunk" ? (index % 2 ? "#FF4FD8" : "#43E8FF") : "#F6EFDD"
            x: ((index * 137) % 39) * root.u
            y: (((index * 71) % 20)) * root.u
            opacity: 0.85
            SequentialAnimation on opacity {
                running: true; loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 + (index % 5) * 300 }
                NumberAnimation { to: 0.9; duration: 700 + (index % 3) * 300 }
            }
        }
    }

    // Sun (desert)
    Rectangle {
        visible: theme === "desert"
        width: root.u * 5; height: width; radius: 0
        color: "#FFE08A"
        x: root.width - width - root.u * 3; y: root.u * 2
    }

    // Cacti (desert & farwest)
    Repeater {
        model: (theme === "desert" || theme === "farwest") ? 2 : 0
        delegate: Item {
            x: root.width * (index ? 0.72 : 0.14)
            y: root.height * root.horizon - root.u * 6
            Rectangle { width: root.u; height: root.u * 6; color: "#3E7D3A"; x: root.u }
            Rectangle { width: root.u * 3; height: root.u; color: "#3E7D3A"; y: root.u * 2 }
            Rectangle { width: root.u; height: root.u * 2; color: "#3E7D3A"; x: root.u * 3; y: root.u }
        }
    }

    // Fence (farwest)
    Row {
        visible: theme === "farwest"
        y: root.height * root.horizon - root.u * 3
        Repeater {
            model: 10
            delegate: Rectangle { width: root.u; height: root.u * 3; color: "#7A5230"
                                  anchors.bottom: undefined; x: index * root.u * 4 }
        }
    }

    // Neon skyline (cyberpunk)
    Row {
        visible: theme === "cyberpunk"
        y: root.height * root.horizon - root.u * 10
        spacing: root.u
        Repeater {
            model: 6
            delegate: Rectangle {
                width: root.u * 3
                height: root.u * (5 + (index * 3) % 6)
                color: "#1B0B2E"
                border.width: 1
                border.color: index % 2 ? "#FF4FD8" : "#43E8FF"
                anchors.bottom: parent.bottom
            }
        }
    }

    // Falling snow (snow)
    Repeater {
        model: theme === "snow" ? 16 : 0
        delegate: Rectangle {
            width: root.u * 0.6; height: width; color: "#FFFFFF"
            x: ((index * 97) % 39) * root.u
            y: 0
            NumberAnimation on y {
                running: true; loops: Animation.Infinite
                from: -root.u; to: root.height
                duration: 3500 + (index % 6) * 900
            }
        }
    }

    // A soft grass fringe on the horizon (grass)
    Row {
        visible: theme === "grass"
        y: root.height * root.horizon - root.u
        Repeater {
            model: 40
            delegate: Rectangle { width: root.u; height: root.u * (index % 3 === 0 ? 1.6 : 1)
                                  color: "#3E7D32" }
        }
    }
}
