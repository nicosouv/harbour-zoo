import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// Shown once, on first launch: pick a blob style, set a name, line up a couple of habits/quests,
// then land on the zoo. Dry, brief, British.
Page {
    id: page
    allowedOrientations: Orientation.All
    backNavigation: false

    property string selectedStyle: "mix"

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

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("Welcome") }

            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("A zoo of odd little creatures, fed by the useful things you do. Two minutes to set up, then it's yours.")
                color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall
            }

            // --- Name --------------------------------------------------------------------------
            SectionHeader { text: qsTr("Your name") }
            TextField {
                id: nameField; width: parent.width
                placeholderText: qsTr("Optional. So the creatures can shout it.")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"; EnterKey.onClicked: focus = false
            }

            // --- Blob style --------------------------------------------------------------------
            SectionHeader { text: qsTr("Blob style") }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Pick one style, or Mix for a bit of everything.")
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
                        // On top of the preview blob (whose own MouseArea would otherwise eat the tap).
                        MouseArea { anchors.fill: parent; onClicked: page.selectedStyle = modelData.id }
                    }
                }
            }

            // --- A couple of habits ------------------------------------------------------------
            SectionHeader { text: qsTr("Habits") }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Tap a few to add them. Or your own below. You can change these anytime.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
            }
            Flow {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                Repeater {
                    model: page.suggested
                    delegate: BackgroundItem {
                        width: chip.width + Theme.paddingLarge; height: Theme.itemSizeExtraSmall
                        onClicked: Zoo.addHabit(modelData.name, modelData.target, "good", "", "", false)
                        Rectangle { anchors.fill: parent; radius: height / 2
                                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.16) }
                        Label {
                            id: chip; anchors.centerIn: parent
                            text: modelData.target > 1 ? modelData.name + " ×" + modelData.target : modelData.name
                            font.pixelSize: Theme.fontSizeExtraSmall; color: Theme.primaryColor
                        }
                    }
                }
            }
            // Your own habit goes through the same page as everywhere else (consistency > cleverness).
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

            // --- One quest (optional) ----------------------------------------------------------
            SectionHeader { text: qsTr("A quest (optional)") }
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

            Item { width: 1; height: Theme.paddingMedium }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                preferredWidth: Theme.buttonWidthLarge
                text: qsTr("Into the zoo")
                onClicked: {
                    if (nameField.text.trim().length > 0) Zoo.playerName = nameField.text.trim()
                    Zoo.blobStyle = page.selectedStyle
                    Zoo.onboarded = true
                    Zoo.grantWelcomeBlob()      // a free first resident, on the house
                    pageStack.pop()
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
