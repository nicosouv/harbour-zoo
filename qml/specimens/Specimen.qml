import QtQuick 2.6

// Base interface every specimen implements (docs/zoo-spec.md §5.4, zoo-specimen skill).
// A specimen is a pure function of (seed, memory): it renders and behaves ONLY from these, and
// emits state changes back to the host, which persists them. It never writes storage itself.
//
// NOTE: the persisted-state members are named `memory` / `persist` (not `state` / `stateChanged`)
// because QML's Item already defines `state` (string) and `stateChanged()` — reusing those names
// would clash. `memory` is the parsed state_json; `persist` is emitted for the host to save.
Item {
    // Reproducible seed — drives ALL procedural params. Same seed => same creature, forever.
    property int seed: 0

    // Identity + persisted interaction state (parsed from state_json by the host).
    property string instanceId: ""
    property var memory: ({})

    // Level of detail: 0 = full-screen, 1 = enclosure ambient (many on screen), 2 = grid thumbnail.
    property int lodLevel: 0

    // Rarity flourish tier: common | uncommon | rare | mythic.
    property string rarity: "common"

    // Host persists on emit (never write storage from QML).
    signal persist(var newMemory)
}
