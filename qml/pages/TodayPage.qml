import QtQuick 2.6
import Sailfish.Silica 1.0
import "../specimens"

// Home. Utility-first: onboarding, the daily challenge, and habit tracking own the body; the zoo
// peeks in from the frame. Voice throughout: dry, sarcastic, British, fond underneath.
Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Settings"); onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml")) }
            MenuItem { text: qsTr("Meet a blob"); onClicked: openBlob(Zoo.newSeed()) }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Zoo")
                description: qsTr("%1 crumbs. Try not to spend them all in one place.").arg(Zoo.crumbs)
            }

            // --- Onboarding (first run) --------------------------------------------------------
            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                visible: !Zoo.onboarded

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    text: qsTr("Right. This is a zoo. It's mostly empty and quietly judging you. "
                               + "Do one small thing a day and keep a habit or two; in return it "
                               + "fills up with peculiar little creatures. That's the whole deal.")
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
                TextField {
                    id: nameField
                    width: parent.width
                    label: qsTr("What should the creatures shout at you? (optional)")
                    placeholderText: qsTr("A name, ideally yours")
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                    EnterKey.onClicked: focus = false
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Fine, let's go")
                    onClicked: {
                        if (nameField.text.trim().length > 0) Zoo.playerName = nameField.text.trim()
                        Zoo.onboarded = true
                    }
                }
            }

            // --- Today's challenge -------------------------------------------------------------
            SectionHeader { text: qsTr("Today") }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    text: qsTr("Your one job. Do it out there in the real world — no buttons will "
                               + "do it for you — then come back and gloat.")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    text: Zoo.todayChallenge
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                }

                // Actions, or the aftermath.
                Row {
                    x: Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium
                    visible: Zoo.todayChallengeStatus === "issued"
                    Button { text: qsTr("Done, obviously"); onClicked: Zoo.completeChallenge() }
                    Button { text: qsTr("Not today"); onClicked: Zoo.skipChallenge() }
                }
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    visible: Zoo.todayChallengeStatus !== "issued"
                    text: Zoo.todayChallengeStatus === "completed"
                          ? qsTr("Done. The zoo is grudgingly impressed. (+15 crumbs, don't let it go to your head.)")
                          : qsTr("Skipped. Bold. We'll say nothing. See you tomorrow, then.")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            // --- Habits (the actually-useful bit) ----------------------------------------------
            SectionHeader { text: qsTr("Habits") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                visible: Zoo.habits.length === 0
                text: qsTr("None yet. Add one you'll actually do — not one that merely looks "
                           + "impressive on a list.")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Repeater {
                model: Zoo.habits
                delegate: ListItem {
                    id: habitItem
                    width: content.width
                    contentHeight: Theme.itemSizeSmall

                    property bool done: modelData.doneToday

                    Label {
                        anchors {
                            left: parent.left; leftMargin: Theme.horizontalPageMargin
                            right: checkBtn.left; rightMargin: Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        text: modelData.name
                        truncationMode: TruncationMode.Fade
                        color: habitItem.done ? Theme.secondaryColor : Theme.primaryColor
                    }
                    IconButton {
                        id: checkBtn
                        anchors {
                            right: parent.right; rightMargin: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        icon.source: habitItem.done ? "image://theme/icon-m-acknowledge"
                                                    : "image://theme/icon-m-add"
                        highlighted: habitItem.done
                        onClicked: if (!habitItem.done) Zoo.logHabit(modelData.id)
                    }

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("Remove, no hard feelings")
                            onClicked: Zoo.removeHabit(modelData.id)
                        }
                    }
                }
            }

            // Add a habit inline.
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                TextField {
                    id: habitField
                    width: parent.width - addBtn.width - Theme.paddingSmall
                    placeholderText: qsTr("Add a habit (e.g. drink water, allegedly)")
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: addHabit()
                }
                IconButton {
                    id: addBtn
                    anchors.verticalCenter: habitField.verticalCenter
                    icon.source: "image://theme/icon-m-add"
                    onClicked: addHabit()
                }
            }

            // --- The reward, peeking in --------------------------------------------------------
            SectionHeader { text: qsTr("Your zoo") }

            Item {
                width: parent.width
                height: page.width * 0.5

                BlobSpecimen {
                    id: peek
                    anchors.centerIn: parent
                    width: page.width * 0.42
                    height: width
                    seed: 1
                    voice: Zoo.playerName
                    lodLevel: 0
                }
                MouseArea { anchors.fill: parent; onClicked: openBlob(peek.seed) }
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Meet another")
                onClicked: peek.seed = Zoo.newSeed()
            }
        }
        VerticalScrollDecorator {}
    }

    function addHabit() {
        if (habitField.text.trim().length === 0) return
        Zoo.addHabit(habitField.text)
        habitField.text = ""
        habitField.focus = false
    }

    function openBlob(seed) {
        pageStack.push(Qt.resolvedUrl("SpecimenPage.qml"), { seed: seed })
    }
}
