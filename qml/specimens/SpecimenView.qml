import QtQuick 2.6

// Picks and hosts the right specimen QML for a species (blob, sprout, …) and exposes the small API
// the zoo/host uses — so callers place a SpecimenView and never care which creature it is.
Item {
    id: root
    property int seed: 0
    property string rarity: "common"
    property string species: "blob"
    property string voice: ""
    property string styleOverride: ""
    property int lodLevel: 1

    readonly property bool speaking: (ld.item && ld.item.speaking !== undefined) ? ld.item.speaking : false
    readonly property string displayName: (ld.item && ld.item.displayName) ? ld.item.displayName : ""
    readonly property string lore: (ld.item && ld.item.lore) ? ld.item.lore : ""
    function react() { if (ld.item && ld.item.react) ld.item.react() }
    function poke() { if (ld.item && ld.item.poke) ld.item.poke() }

    Loader {
        id: ld
        anchors.fill: parent
        source: root.species === "sprout" ? Qt.resolvedUrl("SproutSpecimen.qml")
                                          : Qt.resolvedUrl("BlobSpecimen.qml")
        onLoaded: {
            // Bind reactively so changing seed/rarity (e.g. "Meet another") re-generates the creature.
            item.seed = Qt.binding(function () { return root.seed })
            item.rarity = Qt.binding(function () { return root.rarity })
            item.lodLevel = Qt.binding(function () { return root.lodLevel })
            item.voice = Qt.binding(function () { return root.voice })
            item.styleOverride = Qt.binding(function () { return root.styleOverride })
        }
    }
}
