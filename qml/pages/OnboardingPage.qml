import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"
import "../components"

// The front door. Shown once, on first launch. A tiny living zoo up top (the hook), confetti when
// you commit to something, and dry, clear, engaging copy. Then a free creature on the way in.
Page {
    id: page
    allowedOrientations: Orientation.All
    backNavigation: false

    property string selectedStyle: "mix"
    property var _picked: ({})       // which suggested habits are already added

    readonly property var styleModel: [
        { id: "mix", label: qsTr("Mix") }, { id: "mono", label: "Mono" }, { id: "chonk", label: "Chonk" },
        { id: "ovoid", label: "Ovoid" }, { id: "bean", label: "Bean" }, { id: "hires", label: "Hi-res" },
        { id: "slime", label: "Slime" }, { id: "cyclops", label: "Cyclops" }, { id: "smiley", label: "Smiley" },
        { id: "ghost", label: "Ghost" }
    ]
    readonly property var suggested: [
        { name: qsTr("Drink water"), target: 6 }, { name: qsTr("Read"), target: 1 },
        { name: qsTr("Move a bit"), target: 1 }, { name: qsTr("Breathe"), target: 3 }
    ]

    function celebrate(item) {
        var p = item.mapToItem(page, item.width / 2, item.height / 2)
        confetti.fireAt(p.x, p.y)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("Welcome") }

            // --- The hook: a tiny living zoo, already moving. Styled by your pick, live. ---------
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: page.height * 0.22
                radius: Theme.paddingLarge
                clip: true
                color: "#000000"
                BiomeBackground { id: band; anchors.fill: parent; theme: "grass" }
                Repeater {
                    model: 3
                    delegate: Item {
                        id: rm
                        property real bs: band.width / 6
                        property int dur: 3500
                        width: bs; height: bs
                        function rx() { return Math.random() * Math.max(1, band.width - bs) }
                        function ry() { return band.height * 0.34 + Math.random() * Math.max(1, band.height * 0.52 - bs) }
                        Component.onCompleted: { x = rx(); y = ry() }
                        Behavior on x { NumberAnimation { duration: rm.dur; easing.type: Easing.InOutSine } }
                        Behavior on y { NumberAnimation { duration: rm.dur; easing.type: Easing.InOutSine } }
                        Timer {
                            interval: 2400 + Math.random() * 3000; running: true; repeat: true
                            onTriggered: { rm.dur = 3000 + Math.random() * 3000; rm.x = rm.rx(); rm.y = rm.ry() }
                        }
                        BlobSpecimen {
                            anchors.fill: parent
                            seed: 700 + index * 913
                            styleOverride: page.selectedStyle
                            lodLevel: 1
                        }
                    }
                }
            }

            // --- The pitch (dry, clear) --------------------------------------------------------
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("This is your zoo. Currently empty, faintly judgemental. Let's fix that.")
                color: Theme.primaryColor; font.pixelSize: Theme.fontSizeMedium
            }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Do one small thing a day, earn crumbs, and odd little creatures move in. That is the entire game.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeSmall
            }

            // --- Name --------------------------------------------------------------------------
            SectionHeader { text: qsTr("Your name") }
            TextField {
                id: nameField; width: parent.width
                placeholderText: qsTr("Optional. So the creatures can shout it.")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"; EnterKey.onClicked: focus = false
            }

            // --- Habits: the fuel. Tapping one pops confetti and lands it. ---------------------
            SectionHeader { text: qsTr("Pick a habit or two") }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("The zoo runs on these. Tap a few, or bring your own.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
            }
            Flow {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                Repeater {
                    model: page.suggested
                    delegate: BackgroundItem {
                        id: chipBg
                        property bool picked: page._picked[modelData.name] === true
                        width: chip.width + Theme.paddingLarge; height: Theme.itemSizeExtraSmall
                        enabled: !picked
                        onClicked: {
                            Zoo.addHabit(modelData.name, modelData.target, "good", "", "", false)
                            var m = page._picked; m[modelData.name] = true; page._picked = m
                            page.celebrate(chipBg)
                        }
                        Rectangle {
                            anchors.fill: parent; radius: height / 2
                            color: chipBg.picked ? Theme.rgba(Theme.highlightColor, 0.30)
                                                 : Theme.rgba(Theme.highlightBackgroundColor, 0.16)
                        }
                        Label {
                            id: chip; anchors.centerIn: parent
                            text: (chipBg.picked ? "✓ " : "") + (modelData.target > 1 ? modelData.name + " ×" + modelData.target : modelData.name)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: chipBg.picked ? Theme.highlightColor : Theme.primaryColor
                        }
                    }
                }
            }
            BackgroundItem {
                width: parent.width; height: Theme.itemSizeSmall
                onClicked: pageStack.push(Qt.resolvedUrl("NewHabitPage.qml"))
                Row {
                    anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                    spacing: Theme.paddingSmall
                    Image { source: "image://theme/icon-m-add"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: qsTr("Add your own"); anchors.verticalCenter: parent.verticalCenter
                            color: Theme.highlightColor; font.pixelSize: Theme.fontSizeSmall }
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("%1 habit(s) lined up").arg(Zoo.habits.length)
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeTiny
            }

            // --- Blob look (cosmetic, framed as fun; updates the hero live) --------------------
            SectionHeader { text: qsTr("Your blobs' look") }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Purely cosmetic. Pick a vibe, or Mix and let chaos decide.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
            }
            Grid {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                columns: 4; spacing: Theme.paddingMedium
                Repeater {
                    model: page.styleModel
                    delegate: BackgroundItem {
                        width: (col.width - 2 * Theme.horizontalPageMargin - 3 * Theme.paddingMedium) / 4
                        height: width + Theme.fontSizeExtraSmall + Theme.paddingSmall
                        onClicked: page.selectedStyle = modelData.id
                        Rectangle {
                            anchors.fill: parent; radius: Theme.paddingSmall
                            color: page.selectedStyle === modelData.id
                                   ? Theme.rgba(Theme.highlightColor, 0.30) : "transparent"
                            border.width: page.selectedStyle === modelData.id ? 2 : 0
                            border.color: Theme.highlightColor
                        }
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            BlobSpecimen {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.parent.width * 0.7; height: width
                                seed: 4200 + index * 777
                                styleOverride: modelData.id
                                lodLevel: 1
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label; font.pixelSize: Theme.fontSizeTiny
                                color: Theme.secondaryColor
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: page.selectedStyle = modelData.id }
                    }
                }
            }

            // --- One quest (optional) ----------------------------------------------------------
            SectionHeader { text: qsTr("A quest? (optional)") }
            BackgroundItem {
                width: parent.width; height: Theme.itemSizeSmall
                onClicked: pageStack.push(Qt.resolvedUrl("NewQuestPage.qml"))
                Row {
                    anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                    spacing: Theme.paddingSmall
                    Image { source: "image://theme/icon-m-add"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: qsTr("New quest"); anchors.verticalCenter: parent.verticalCenter
                            color: Theme.highlightColor; font.pixelSize: Theme.fontSizeSmall }
                }
            }

            // --- Land, with a gift ------------------------------------------------------------
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter
                text: qsTr("Step inside and we'll hand you your first creature. Free. Because we're generous, apparently.")
                color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeExtraSmall; font.italic: true
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                preferredWidth: Theme.buttonWidthLarge
                text: qsTr("Into the zoo")
                onClicked: {
                    if (nameField.text.trim().length > 0) Zoo.playerName = nameField.text.trim()
                    Zoo.blobStyle = page.selectedStyle
                    confetti.fireAt(page.width / 2, page.height * 0.5)   // a proper send-off
                    landTimer.start()
                }
            }
            Item { width: 1; height: Theme.paddingLarge }
        }
        VerticalScrollDecorator {}
    }

    // Let the confetti actually show before we leave the page.
    Timer {
        id: landTimer; interval: 700; repeat: false
        onTriggered: { Zoo.onboarded = true; Zoo.grantWelcomeBlob(); pageStack.pop() }
    }

    ConfettiBurst { id: confetti }
}
