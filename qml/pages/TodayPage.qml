import QtQuick 2.6
import Sailfish.Silica 1.0

// Home. The USEFUL loop lives here — challenge, habits, quests — and it visibly feeds the zoo.
// Voice: dry, sarcastic, British, fond underneath. See docs/ui-ux-system.md.
Page {
    id: page
    allowedOrientations: Orientation.All

    property string pendingDue: ""

    Component { id: dueDialog; DatePickerDialog { } }

    function pickDue() {
        var d = pageStack.push(dueDialog)
        d.accepted.connect(function () { page.pendingDue = Qt.formatDate(d.date, "yyyy-MM-dd") })
    }
    function addQuest() {
        if (questField.text.trim().length === 0) return
        Zoo.addQuest(questField.text, page.pendingDue)
        questField.text = ""
        page.pendingDue = ""
        questField.focus = false
    }
    function addHabit() {
        if (habitField.text.trim().length === 0) return
        Zoo.addHabit(habitField.text)
        habitField.text = ""
        habitField.focus = false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Settings"); onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml")) }
            MenuItem { text: qsTr("Your zoo"); onClicked: pageStack.push(Qt.resolvedUrl("ZooPage.qml")) }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Zoo")
                description: qsTr("🍞 %1 crumbs").arg(Zoo.crumbs)
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
                    text: qsTr("Right. This is a zoo. It's empty and quietly judging you. Do useful "
                               + "things — a daily challenge, habits, the odd quest — to earn crumbs. "
                               + "Crumbs hatch peculiar little creatures and buy them nice things. "
                               + "That's the entire arrangement: your follow-through builds the zoo.")
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
            SectionHeader { text: qsTr("Today's challenge") }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    text: qsTr("One job. Do it out in the real world — no button will do it for you — "
                               + "then come back and gloat. (+15 🍞)")
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
                          ? qsTr("Done. The zoo is grudgingly impressed. (+15 🍞)")
                          : qsTr("Skipped. Bold. We'll say nothing. Tomorrow, then.")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            // --- Habits (recurring) ------------------------------------------------------------
            SectionHeader { text: qsTr("Habits — the daily kind") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                visible: Zoo.habits.length === 0
                text: qsTr("None yet. Add one you'll actually do — not one that merely looks good "
                           + "on a list. Each check-in is +5 🍞.")
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
                    onClicked: if (!done) Zoo.logHabit(modelData.id)

                    Rectangle {
                        id: circle
                        anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin
                                  verticalCenter: parent.verticalCenter }
                        width: Theme.iconSizeSmall; height: width; radius: width / 2
                        color: habitItem.done ? Theme.highlightColor : "transparent"
                        border.width: 2
                        border.color: habitItem.done ? Theme.highlightColor : Theme.secondaryColor
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Label {
                            anchors.centerIn: parent
                            text: "✓"
                            visible: habitItem.done
                            color: "#20233A"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                        }
                    }
                    Label {
                        anchors { left: circle.right; leftMargin: Theme.paddingMedium
                                  right: reward.left; rightMargin: Theme.paddingSmall
                                  verticalCenter: parent.verticalCenter }
                        text: modelData.name
                        truncationMode: TruncationMode.Fade
                        color: habitItem.done ? Theme.secondaryColor : Theme.primaryColor
                    }
                    Label {
                        id: reward
                        anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin
                                  verticalCenter: parent.verticalCenter }
                        text: habitItem.done ? qsTr("done") : qsTr("+5 🍞")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    menu: ContextMenu {
                        MenuItem { text: qsTr("Remove, no hard feelings")
                                   onClicked: Zoo.removeHabit(modelData.id) }
                    }
                }
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                TextField {
                    id: habitField
                    width: parent.width - habitAdd.width - Theme.paddingSmall
                    placeholderText: qsTr("Add a habit (e.g. drink water, allegedly)")
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: addHabit()
                }
                IconButton {
                    id: habitAdd
                    anchors.verticalCenter: habitField.verticalCenter
                    icon.source: "image://theme/icon-m-add"
                    onClicked: addHabit()
                }
            }

            // --- Quests (one-off, optional deadline) -------------------------------------------
            SectionHeader { text: qsTr("Quests — one and done") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                visible: Zoo.quests.length === 0
                text: qsTr("For the one-off things: 'fix the bike', 'ring the dentist'. Give them a "
                           + "deadline if you're feeling brave. Worth +20 🍞 each.")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Repeater {
                model: Zoo.quests
                delegate: ListItem {
                    width: content.width
                    contentHeight: Theme.itemSizeSmall
                    Column {
                        anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin
                                  right: doneBtn.left; rightMargin: Theme.paddingMedium
                                  verticalCenter: parent.verticalCenter }
                        Label {
                            width: parent.width
                            text: modelData.name
                            truncationMode: TruncationMode.Fade
                        }
                        Label {
                            visible: modelData.due.length > 0
                            text: modelData.overdue ? qsTr("was due %1 — no judgement").arg(modelData.due)
                                                    : qsTr("by %1").arg(modelData.due)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: modelData.overdue ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                    Button {
                        id: doneBtn
                        anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin
                                  verticalCenter: parent.verticalCenter }
                        text: qsTr("Done")
                        onClicked: Zoo.completeQuest(modelData.id)
                    }
                    menu: ContextMenu {
                        MenuItem { text: qsTr("Bin it"); onClicked: Zoo.removeQuest(modelData.id) }
                    }
                }
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                Row {
                    width: parent.width
                    spacing: Theme.paddingSmall
                    TextField {
                        id: questField
                        width: parent.width - questAdd.width - Theme.paddingSmall
                        placeholderText: qsTr("Add a quest")
                        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                        EnterKey.onClicked: addQuest()
                    }
                    IconButton {
                        id: questAdd
                        anchors.verticalCenter: questField.verticalCenter
                        icon.source: "image://theme/icon-m-add"
                        onClicked: addQuest()
                    }
                }
                Row {
                    spacing: Theme.paddingMedium
                    IconButton {
                        icon.source: "image://theme/icon-m-date"
                        onClicked: pickDue()
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.pendingDue.length > 0 ? qsTr("due %1").arg(page.pendingDue)
                                                         : qsTr("no deadline (living dangerously)")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            // --- The link to the zoo -----------------------------------------------------------
            SectionHeader { text: qsTr("Your zoo") }

            BackgroundItem {
                width: parent.width
                height: zooRow.height + 2 * Theme.paddingMedium
                onClicked: pageStack.push(Qt.resolvedUrl("ZooPage.qml"))
                Row {
                    id: zooRow
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingMedium
                    Column {
                        width: parent.width - Theme.iconSizeSmall - Theme.paddingMedium
                        Label {
                            text: Zoo.ownedBlobs.length === 0
                                  ? qsTr("Open the zoo — it's waiting")
                                  : qsTr("%1 residents, all yours").arg(Zoo.ownedBlobs.length)
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: qsTr("Spend crumbs here to hatch blobs and buy them things.")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/icon-m-right"
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
