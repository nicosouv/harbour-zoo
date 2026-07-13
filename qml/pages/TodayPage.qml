import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

// The useful loop (reached from the zoo via "Today"): challenge, habits, quests. Light copy, dry
// British voice. Everything here earns crumbs that feed the zoo, and a little confetti.
Page {
    id: page
    allowedOrientations: Orientation.All

    function celebrate(item) {
        var p = item.mapToItem(page, item.width / 2, item.height / 2)
        confetti.fireAt(p.x, p.y)
    }

    // Pomodoro selection only, the timer itself runs in the engine (survives navigation).
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
    property bool habitTolerated: false
    function addHabit() {
        if (habitField.text.trim().length === 0) return
        Zoo.addHabit(habitField.text, habitTarget, habitKind,
                     cueField.text, replacementField.text, habitTolerated)
        habitField.text = ""; cueField.text = ""; replacementField.text = ""
        habitTarget = 1; habitKind = "good"; habitTolerated = false; habitField.focus = false
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

            // --- Emotional check-in ------------------------------------------------------------
            // One optional tap. It never gates action, it just right-sizes today's ask (a low day
            // means "go tiny, and tiny counts"). See the evidence base in docs/utility-spine.md.
            Column {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                Label {
                    text: qsTr("How are you, right now?")
                    color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeExtraSmall
                }
                Row {
                    spacing: Theme.paddingLarge
                    Repeater {
                        model: [ { v: 1, e: "😞" }, { v: 2, e: "🙁" }, { v: 3, e: "😐" }, { v: 4, e: "🙂" }, { v: 5, e: "😄" } ]
                        delegate: BackgroundItem {
                            width: Theme.iconSizeMedium; height: Theme.iconSizeMedium
                            onClicked: Zoo.logMood(modelData.v)
                            Label {
                                anchors.centerIn: parent; text: modelData.e
                                font.pixelSize: Theme.fontSizeLarge
                                opacity: (Zoo.todayMood === 0 || Zoo.todayMood === modelData.v) ? 1.0 : 0.35
                            }
                        }
                    }
                }
                Label {
                    width: parent.width; visible: Zoo.moodReadiness.length > 0; wrapMode: Text.Wrap
                    text: Zoo.moodReadiness; color: Theme.highlightColor; font.pixelSize: Theme.fontSizeSmall
                }
            }

            // Gentle behaviour-science nudges: never-miss-twice / welcome-back, and fresh-start.
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                visible: Zoo.gentleNudge.length > 0; wrapMode: Text.Wrap
                text: Zoo.gentleNudge; color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall; font.italic: true
            }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                visible: Zoo.freshStartPrompt.length > 0; wrapMode: Text.Wrap
                text: Zoo.freshStartPrompt; color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall; font.italic: true
            }

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
                    id: habitItem; width: content.width
                    contentHeight: Math.max(Theme.itemSizeSmall, infoCol.height + Theme.paddingMedium)
                    property bool bad: modelData.bad
                    property bool done: modelData.doneToday      // good: target met; bad: clean today
                    property bool multi: !bad && modelData.target > 1
                    onClicked: {
                        if (bad) { Zoo.logHabit(modelData.id) }   // a slip, recorded, no confetti
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
                        id: infoCol
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
                                id: avoidTag; visible: habitItem.bad
                                text: modelData.tolerated ? qsTr("tolerated") : qsTr("avoid")
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
                        // The anchor (implementation intention), quietly reinforces when to act.
                        Label {
                            width: parent.width; visible: modelData.cue.length > 0; wrapMode: Text.Wrap
                            text: "⏱ " + modelData.cue
                            color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeTiny
                        }
                        // Never miss twice: a warm one-liner on the single-miss day, never a scold.
                        Label {
                            width: parent.width; wrapMode: Text.Wrap
                            visible: modelData.missedYesterday && !habitItem.done
                            text: qsTr("missed yesterday, today's the one that keeps it")
                            color: Theme.highlightColor; font.pixelSize: Theme.fontSizeTiny
                        }
                        // The swap for a bad habit, surfaced right where the slip happens.
                        Label {
                            width: parent.width
                            visible: habitItem.bad && modelData.replacement.length > 0; wrapMode: Text.Wrap
                            text: qsTr("↪ instead: %1").arg(modelData.replacement)
                            color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeTiny
                        }
                        // The tolerance window has closed, a gentle re-ask, never a scold.
                        Column {
                            width: parent.width; visible: modelData.toleranceExpired
                            spacing: Theme.paddingSmall
                            Label {
                                width: parent.width; wrapMode: Text.Wrap
                                text: qsTr("Your 'ok for now' window closed. Extend it, or let it count again?")
                                color: Theme.highlightColor; font.pixelSize: Theme.fontSizeTiny
                            }
                            Row {
                                spacing: Theme.paddingMedium
                                Button { text: qsTr("Two more weeks"); font.pixelSize: Theme.fontSizeTiny
                                         onClicked: Zoo.extendTolerance(modelData.id) }
                                Button { text: qsTr("Let it count"); font.pixelSize: Theme.fontSizeTiny
                                         onClicked: Zoo.tightenTolerance(modelData.id) }
                            }
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
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: cueField.focus = true
                }
                // Implementation intention / anchor, the single strongest lever for follow-through.
                TextField {
                    id: cueField; width: parent.width
                    placeholderText: qsTr("When? e.g. after my morning coffee")
                    label: qsTr("Cue (optional)")
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: page.habitKind === "bad" ? (replacementField.focus = true) : addHabit()
                }
                // For a bad habit: the swap (same reward) and whether to tolerate it for now.
                TextField {
                    id: replacementField; width: parent.width
                    visible: page.habitKind === "bad"
                    placeholderText: qsTr("Instead, I'll… (same payoff, kinder)")
                    label: qsTr("Replacement (optional)")
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: addHabit()
                }
                Row {
                    spacing: Theme.paddingMedium
                    Button {
                        text: page.habitKind === "good" ? "🙂" : "⚠️"
                        onClicked: page.habitKind = page.habitKind === "good" ? "bad" : "good"
                    }
                    Button {
                        visible: page.habitKind === "good"
                        text: "×" + page.habitTarget
                        onClicked: page.habitTarget = page.habitTarget >= 8 ? 1 : page.habitTarget + 1
                    }
                    Button {
                        visible: page.habitKind === "bad"
                        text: page.habitTolerated ? qsTr("tolerated") : qsTr("tighten")
                        color: page.habitTolerated ? Theme.secondaryHighlightColor : Theme.primaryColor
                        onClicked: page.habitTolerated = !page.habitTolerated
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.habitKind === "good" ? qsTr("times/day")
                              : (page.habitTolerated ? qsTr("ok for now") : qsTr("avoid this one"))
                        color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: "image://theme/icon-m-add"; onClicked: addHabit()
                    }
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
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: "image://theme/icon-m-date"; onClicked: pickDue()
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.pendingDue.length > 0 ? page.pendingDue : qsTr("no deadline")
                        color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: "image://theme/icon-m-add"; onClicked: addQuest()
                    }
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
