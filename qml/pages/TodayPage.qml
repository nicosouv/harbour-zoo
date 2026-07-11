import QtQuick 2.6
import Sailfish.Silica 1.0

// Home. Light and essential: a status strip, the day's challenge, habits, quests. Everything
// earns crumbs that feed the zoo. Voice: dry, sarcastic, British.
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
        questField.text = ""; page.pendingDue = ""; questField.focus = false
    }
    function addHabit() {
        if (habitField.text.trim().length === 0) return
        Zoo.addHabit(habitField.text); habitField.text = ""; habitField.focus = false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem { text: qsTr("Settings"); onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml")) }
            MenuItem { text: qsTr("Keeper"); onClicked: pageStack.push(Qt.resolvedUrl("KeeperPage.qml")) }
            MenuItem { text: qsTr("Your zoo"); onClicked: pageStack.push(Qt.resolvedUrl("ZooPage.qml")) }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("Zoo") }

            // --- Status strip (gamification at a glance) ---------------------------------------
            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                onClicked: pageStack.push(Qt.resolvedUrl("KeeperPage.qml"))
                Row {
                    anchors {
                        left: parent.left; leftMargin: Theme.horizontalPageMargin
                        right: parent.right; rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    Column {
                        width: parent.width * 0.42
                        Label { text: Zoo.keeperTitle; color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeSmall; truncationMode: TruncationMode.Fade }
                        Label { text: qsTr("Level %1").arg(Zoo.keeperLevel); color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeTiny }
                    }
                    Row {
                        width: parent.width * 0.58
                        layoutDirection: Qt.RightToLeft
                        spacing: Theme.paddingMedium
                        Label { text: "🍞 " + Zoo.crumbs; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                        Label { text: "🥚 " + Zoo.ownedBlobs.length; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                        Label { text: "🔥 " + Zoo.streak; color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall }
                    }
                }
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
                    text: qsTr("A zoo. Empty, judgemental. Do useful things → earn crumbs → hatch odd creatures.")
                    color: Theme.primaryColor; font.pixelSize: Theme.fontSizeSmall
                }
                TextField {
                    id: nameField; width: parent.width
                    label: qsTr("Name? (optional)")
                    placeholderText: qsTr("So they can shout it")
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                    EnterKey.onClicked: focus = false
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Go")
                    onClicked: {
                        if (nameField.text.trim().length > 0) Zoo.playerName = nameField.text.trim()
                        Zoo.onboarded = true
                    }
                }
            }

            // --- Challenge ---------------------------------------------------------------------
            SectionHeader { text: qsTr("Today") }
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
                    Button { text: qsTr("Done"); onClicked: Zoo.completeChallenge() }
                    Button { text: qsTr("Skip"); onClicked: Zoo.skipChallenge() }
                }
                Label {
                    x: Theme.horizontalPageMargin
                    visible: Zoo.todayChallengeStatus !== "issued"
                    text: Zoo.todayChallengeStatus === "completed" ? qsTr("Done. +15 🍞")
                                                                   : qsTr("Skipped. Bold.")
                    color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeSmall
                }
            }

            // --- Habits ------------------------------------------------------------------------
            SectionHeader { text: qsTr("Habits") }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: Zoo.habits.length === 0; wrapMode: Text.Wrap
                text: qsTr("Add one you'll actually do."); color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Repeater {
                model: Zoo.habits
                delegate: ListItem {
                    id: habitItem; width: content.width; contentHeight: Theme.itemSizeSmall
                    property bool done: modelData.doneToday
                    onClicked: if (!done) Zoo.logHabit(modelData.id)
                    Rectangle {
                        id: circle
                        anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                        width: Theme.iconSizeSmall; height: width; radius: width / 2
                        color: habitItem.done ? Theme.highlightColor : "transparent"
                        border.width: 2
                        border.color: habitItem.done ? Theme.highlightColor : Theme.secondaryColor
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Label { anchors.centerIn: parent; text: "✓"; visible: habitItem.done
                                color: "#20233A"; font.pixelSize: Theme.fontSizeSmall; font.bold: true }
                    }
                    Label {
                        anchors { left: circle.right; leftMargin: Theme.paddingMedium
                                  right: parent.right; rightMargin: Theme.horizontalPageMargin
                                  verticalCenter: parent.verticalCenter }
                        text: modelData.name; truncationMode: TruncationMode.Fade
                        color: habitItem.done ? Theme.secondaryColor : Theme.primaryColor
                    }
                    menu: ContextMenu {
                        MenuItem { text: qsTr("Remove"); onClicked: Zoo.removeHabit(modelData.id) }
                    }
                }
            }
            Row {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                TextField {
                    id: habitField; width: parent.width - habitAdd.width - Theme.paddingSmall
                    placeholderText: qsTr("New habit (+5 🍞)")
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: addHabit()
                }
                IconButton { id: habitAdd; anchors.verticalCenter: habitField.verticalCenter
                             icon.source: "image://theme/icon-m-add"; onClicked: addHabit() }
            }

            // --- Quests ------------------------------------------------------------------------
            SectionHeader { text: qsTr("Quests") }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: Zoo.quests.length === 0; wrapMode: Text.Wrap
                text: qsTr("One-off things go here."); color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Repeater {
                model: Zoo.quests
                delegate: ListItem {
                    width: content.width; contentHeight: Theme.itemSizeSmall
                    Column {
                        anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin
                                  right: doneBtn.left; rightMargin: Theme.paddingMedium
                                  verticalCenter: parent.verticalCenter }
                        Label { width: parent.width; text: modelData.name; truncationMode: TruncationMode.Fade }
                        Label {
                            visible: modelData.due.length > 0
                            text: modelData.overdue ? qsTr("was due %1").arg(modelData.due)
                                                    : qsTr("by %1").arg(modelData.due)
                            font.pixelSize: Theme.fontSizeTiny
                            color: modelData.overdue ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                    Button {
                        id: doneBtn
                        anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                        text: qsTr("Done"); onClicked: Zoo.completeQuest(modelData.id)
                    }
                    menu: ContextMenu { MenuItem { text: qsTr("Bin it"); onClicked: Zoo.removeQuest(modelData.id) } }
                }
            }
            Row {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall
                TextField {
                    id: questField; width: parent.width - questDate.width - questAdd.width - 2 * Theme.paddingSmall
                    placeholderText: page.pendingDue.length > 0 ? qsTr("New quest · %1").arg(page.pendingDue)
                                                                : qsTr("New quest (+20 🍞)")
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: addQuest()
                }
                IconButton { id: questDate; anchors.verticalCenter: questField.verticalCenter
                             icon.source: "image://theme/icon-m-date"; onClicked: pickDue() }
                IconButton { id: questAdd; anchors.verticalCenter: questField.verticalCenter
                             icon.source: "image://theme/icon-m-add"; onClicked: addQuest() }
            }

            // --- Zoo link ----------------------------------------------------------------------
            BackgroundItem {
                width: parent.width; height: Theme.itemSizeSmall
                onClicked: pageStack.push(Qt.resolvedUrl("ZooPage.qml"))
                Label {
                    anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                    text: qsTr("Your zoo · %1 residents").arg(Zoo.ownedBlobs.length)
                    color: Theme.primaryColor
                }
                Image {
                    anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                    source: "image://theme/icon-m-right"
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
