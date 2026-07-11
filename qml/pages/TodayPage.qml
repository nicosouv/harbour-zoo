import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

// The useful loop (reached from the zoo via "Today"): challenge, habits, quests. Light copy, dry
// British voice. Everything here earns crumbs that feed the zoo — and a little confetti.
Page {
    id: page
    allowedOrientations: Orientation.All

    function celebrate(item) {
        var p = item.mapToItem(page, item.width / 2, item.height / 2)
        confetti.fireAt(p.x, p.y)
    }

    // Pomodoro selection only — the timer itself runs in the engine (survives navigation).
    property int focusMin: 25
    function mmss(s) { var m = Math.floor(s / 60), r = s % 60; return m + ":" + (r < 10 ? "0" + r : r) }

    property string pendingDue: ""

    Component { id: dueDialog; DatePickerDialog { } }
    function pickDue() {
        var d = pageStack.push(dueDialog)
        d.accepted.connect(function () { page.pendingDue = Qt.formatDate(d.date, "yyyy-MM-dd") })
    }
    function addQuest() {
        if (questField.text.trim().length === 0) return
        Zoo.addQuest(questField.text, page.pendingDue)
        questField.text = ""; page.pendingDue = ""; questField.focus = false
    }
    property int habitTarget: 1
    property string habitKind: "good"
    function addHabit() {
        if (habitField.text.trim().length === 0) return
        Zoo.addHabit(habitField.text, habitTarget, habitKind)
        habitField.text = ""; habitTarget = 1; habitKind = "good"; habitField.focus = false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Settings"); onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml")) }
            MenuItem { text: qsTr("Keeper"); onClicked: pageStack.push(Qt.resolvedUrl("KeeperPage.qml")) }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("Today"); description: qsTr("🍞 %1 crumbs").arg(Zoo.crumbs) }

            // --- Challenge ---------------------------------------------------------------------
            SectionHeader { text: qsTr("Challenge") }
            Column {
                width: parent.width; spacing: Theme.paddingSmall
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap; text: Zoo.todayChallenge
                    color: Theme.highlightColor; font.pixelSize: Theme.fontSizeMedium
                }
                Row {
                    x: Theme.horizontalPageMargin; spacing: Theme.paddingMedium
                    visible: Zoo.todayChallengeStatus === "issued"
                    Button { id: challengeDone; text: qsTr("Done")
                             onClicked: { page.celebrate(challengeDone); Zoo.completeChallenge() } }
                    Button { text: qsTr("Skip"); onClicked: Zoo.skipChallenge() }
                }
                Label {
                    x: Theme.horizontalPageMargin
                    visible: Zoo.todayChallengeStatus !== "issued"
                    text: Zoo.todayChallengeStatus === "completed" ? qsTr("Done. +15 🍞") : qsTr("Skipped. Bold.")
                    color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeSmall
                }
            }

            // --- Focus (pomodoro) --------------------------------------------------------------
            SectionHeader { text: qsTr("Focus") }
            Column {
                width: parent.width; spacing: Theme.paddingSmall

                Row {
                    id: presetRow
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    spacing: Theme.paddingSmall
                    visible: !Zoo.focusRunning
                    Repeater {
                        model: [5, 15, 25, 45]
                        delegate: Button {
                            width: (presetRow.width - 3 * Theme.paddingSmall) / 4
                            text: modelData + "m"
                            color: page.focusMin === modelData ? Theme.highlightColor : Theme.primaryColor
                            onClicked: page.focusMin = modelData
                        }
                    }
                }
                Button {
                    x: Theme.horizontalPageMargin
                    visible: !Zoo.focusRunning
                    text: qsTr("Start %1 min").arg(page.focusMin)
                    onClicked: Zoo.startFocus(page.focusMin)
                }

                Column {
                    x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                    spacing: Theme.paddingSmall
                    visible: Zoo.focusRunning
                    Label { text: page.mmss(Zoo.focusRemaining); color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeHuge }
                    ProgressBar {
                        width: parent.width; minimumValue: 0
                        maximumValue: Math.max(1, Zoo.focusMinutes * 60)
                        value: Zoo.focusMinutes * 60 - Zoo.focusRemaining
                    }
                    Label { width: parent.width; wrapMode: Text.Wrap
                            text: qsTr("Focusing. The blobs are being very quiet for you.")
                            color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeSmall }
                    Button { text: qsTr("Give up (no shame)"); onClicked: Zoo.stopFocus() }
                }
            }

            // --- Habits ------------------------------------------------------------------------
            SectionHeader { text: qsTr("Habits") }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                visible: Zoo.habits.length === 0; wrapMode: Text.Wrap
                text: qsTr("Add one you'll actually do."); color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Repeater {
                model: Zoo.habits
                delegate: ListItem {
                    id: habitItem; width: content.width; contentHeight: Theme.itemSizeSmall
                    property bool bad: modelData.bad
                    property bool done: modelData.doneToday      // good: target met; bad: clean today
                    property bool multi: !bad && modelData.target > 1
                    onClicked: {
                        if (bad) { Zoo.logHabit(modelData.id) }   // a slip — recorded, no confetti
                        else if (modelData.doneCount < modelData.target) { page.celebrate(circle); Zoo.logHabit(modelData.id) }
                    }
                    Rectangle {
                        id: circle
                        anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                        width: Theme.iconSizeSmall; height: width; radius: width / 2
                        color: (!habitItem.bad && habitItem.done) ? Theme.highlightColor : "transparent"
                        border.width: 2
                        border.color: habitItem.bad ? Theme.secondaryHighlightColor
                                     : (habitItem.done ? Theme.highlightColor : Theme.secondaryColor)
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Label {
                            anchors.centerIn: parent
                            text: habitItem.bad ? (modelData.slips > 0 ? modelData.slips : "")
                                                : (habitItem.done ? "✓" : (habitItem.multi ? modelData.doneCount : ""))
                            visible: text.length > 0
                            color: (!habitItem.bad && habitItem.done) ? "#20233A" : Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall; font.bold: true
                        }
                    }
                    Column {
                        anchors { left: circle.right; leftMargin: Theme.paddingMedium
                                  right: parent.right; rightMargin: Theme.horizontalPageMargin
                                  verticalCenter: parent.verticalCenter }
                        Row {
                            width: parent.width; spacing: Theme.paddingSmall
                            Label {
                                text: modelData.name; truncationMode: TruncationMode.Fade
                                color: habitItem.done ? Theme.secondaryColor : Theme.primaryColor
                                width: Math.min(implicitWidth, parent.width - (habitItem.bad ? avoidTag.width + Theme.paddingSmall : 0))
                            }
                            Label {
                                id: avoidTag; visible: habitItem.bad; text: qsTr("avoid")
                                color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeTiny
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        Label {
                            text: habitItem.bad
                                  ? (modelData.slips > 0 ? qsTr("slipped %1 today").arg(modelData.slips) : qsTr("clean today, nice"))
                                  : (habitItem.multi
                                     ? qsTr("%1 / %2 today").arg(modelData.doneCount).arg(modelData.target)
                                     : (habitItem.done ? qsTr("✓ today")
                                        : (modelData.lastDone.length > 0 ? qsTr("last: %1").arg(modelData.lastDone)
                                                                         : qsTr("not yet"))))
                            color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeTiny
                        }
                    }
                    menu: ContextMenu { MenuItem { text: qsTr("Remove"); onClicked: Zoo.removeHabit(modelData.id) } }
                }
            }
            Column {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                TextField {
                    id: habitField; width: parent.width
                    placeholderText: qsTr("New habit (+5 🍞)")
                    label: qsTr("New habit")
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: addHabit()
                }
                Row {
                    spacing: Theme.paddingMedium
                    Button {
                        text: page.habitKind === "good" ? qsTr("Good") : qsTr("Bad (avoid)")
                        color: page.habitKind === "good" ? Theme.primaryColor : Theme.secondaryHighlightColor
                        onClicked: page.habitKind = page.habitKind === "good" ? "bad" : "good"
                    }
                    Button {
                        visible: page.habitKind === "good"
                        text: qsTr("×%1/day").arg(page.habitTarget)
                        onClicked: page.habitTarget = page.habitTarget >= 8 ? 1 : page.habitTarget + 1
                    }
                    Button { text: qsTr("Add"); onClicked: addHabit() }
                }
            }

            // --- Quests ------------------------------------------------------------------------
            SectionHeader { text: qsTr("Quests") }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                visible: Zoo.quests.length === 0; wrapMode: Text.Wrap
                text: qsTr("One-off things go here."); color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Repeater {
                model: Zoo.quests
                delegate: ListItem {
                    width: content.width; contentHeight: Theme.itemSizeSmall
                    onClicked: { page.celebrate(doneEmoji); Zoo.completeQuest(modelData.id) }
                    Column {
                        anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin
                                  right: doneEmoji.left; rightMargin: Theme.paddingMedium; verticalCenter: parent.verticalCenter }
                        Label { width: parent.width; text: modelData.name; truncationMode: TruncationMode.Fade }
                        Label {
                            visible: modelData.due.length > 0
                            text: modelData.overdue ? qsTr("was due %1").arg(modelData.due) : qsTr("by %1").arg(modelData.due)
                            font.pixelSize: Theme.fontSizeTiny
                            color: modelData.overdue ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                    // Tap the row (or this) to complete. No button; just a satisfying tick.
                    Label {
                        id: doneEmoji
                        anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                        text: "⬜"; font.pixelSize: Theme.fontSizeLarge
                    }
                    menu: ContextMenu { MenuItem { text: qsTr("Bin it"); onClicked: Zoo.removeQuest(modelData.id) } }
                }
            }
            Column {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                TextField {
                    id: questField; width: parent.width
                    label: qsTr("New quest")
                    placeholderText: qsTr("New quest (+20 🍞)")
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: addQuest()
                }
                Row {
                    spacing: Theme.paddingMedium
                    Button {
                        text: page.pendingDue.length > 0 ? qsTr("Due %1").arg(page.pendingDue) : qsTr("Set date")
                        onClicked: pickDue()
                    }
                    Button { text: qsTr("Add"); onClicked: addQuest() }
                }
            }
        }
        VerticalScrollDecorator {}
    }

    // Confetti overlay, fired on a validation.
    ConfettiBurst { id: confetti }

    // Celebrate a finished focus session even if it completes while on this page.
    Connections {
        target: Zoo
        onFocusFinished: confetti.fireAt(page.width / 2, page.height * 0.4)
    }
}
