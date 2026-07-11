import QtQuick 2.6

// Top-down pixel-art ground for the enclosure. The whole area is floor (no sky), so blobs roam on
// solid ground rather than appearing to fly. Objects (trees, rocks…) are separate props on top.
Item {
    id: root
    property string theme: "night"
    clip: true

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/biomes/" + root.theme + ".png")
        fillMode: Image.PreserveAspectCrop
        smooth: false            // crisp, chunky pixels
        asynchronous: true
        onStatusChanged: if (status === Image.Error) source = Qt.resolvedUrl("../images/biomes/night.png")
    }
}
