import QtQuick 2.6
import Sailfish.Silica 1.0

// Settings + About in one page. Gentle by design: the only toggle is an opt-in reminder, OFF by
// default (no nagging). About lives at the bottom, closing on the signature line.
Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Settings") }

            // --- You -------------------------------------------------------------------------
            SectionHeader { text: qsTr("You") }

            TextField {
                width: parent.width
                label: qsTr("Your name (so the creatures can shout it)")
                placeholderText: qsTr("Optional. They'll manage either way.")
                text: Zoo.playerName
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
                onTextChanged: if (text !== Zoo.playerName) Zoo.playerName = text
            }
            Component { id: bdayDialog; DatePickerDialog { } }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Zoo.playerBirthday.length > 0 ? qsTr("Birthday: %1").arg(Zoo.playerBirthday)
                                                    : qsTr("Set birthday (optional)")
                onClicked: {
                    var d = pageStack.push(bdayDialog)
                    d.accepted.connect(function () { Zoo.playerBirthday = Qt.formatDate(d.date, "MM-dd") })
                }
            }

            // --- Language --------------------------------------------------------------------
            SectionHeader { text: qsTr("Language") }

            ComboBox {
                id: langCombo
                property var codes: ["", "en", "fr", "de", "it", "es", "fi"]
                label: qsTr("Language")
                currentIndex: Math.max(0, codes.indexOf(Zoo.language))
                menu: ContextMenu {
                    MenuItem { text: qsTr("System default") }
                    MenuItem { text: "English" }
                    MenuItem { text: "Français" }
                    MenuItem { text: "Deutsch" }
                    MenuItem { text: "Italiano" }
                    MenuItem { text: "Español" }
                    MenuItem { text: "Suomi" }
                }
                onCurrentIndexChanged: {
                    var c = codes[currentIndex]
                    if (c !== Zoo.language) Zoo.language = c
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Takes effect next time you open Zoo.")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            // --- Blobs -----------------------------------------------------------------------
            SectionHeader { text: qsTr("Blobs") }
            ComboBox {
                property var codes: ["mix", "mono", "chonk", "ovoid", "bean", "hires", "slime", "cyclops", "smiley", "ghost"]
                label: qsTr("Blob style")
                currentIndex: Math.max(0, codes.indexOf(Zoo.blobStyle))
                menu: ContextMenu {
                    MenuItem { text: qsTr("Mix of all styles") }
                    MenuItem { text: "Mono" }
                    MenuItem { text: "Chonk" }
                    MenuItem { text: "Ovoid" }
                    MenuItem { text: "Bean" }
                    MenuItem { text: "Hi-res" }
                    MenuItem { text: "Slime" }
                    MenuItem { text: "Cyclops" }
                    MenuItem { text: "Smiley" }
                    MenuItem { text: "Ghost" }
                }
                onCurrentIndexChanged: { var c = codes[currentIndex]; if (c !== Zoo.blobStyle) Zoo.blobStyle = c }
            }
            ComboBox {
                property var sizes: [0.7, 1.0, 1.3, 1.6]
                label: qsTr("Blob size")
                currentIndex: {
                    var best = 1, bd = 99
                    for (var i = 0; i < sizes.length; i++) { var d = Math.abs(sizes[i] - Zoo.blobScale); if (d < bd) { bd = d; best = i } }
                    return best
                }
                menu: ContextMenu {
                    MenuItem { text: qsTr("Small") }
                    MenuItem { text: qsTr("Medium") }
                    MenuItem { text: qsTr("Large") }
                    MenuItem { text: qsTr("Enormous") }
                }
                onCurrentIndexChanged: { var s = sizes[currentIndex]; if (s !== Zoo.blobScale) Zoo.blobScale = s }
            }

            // --- Testing ---------------------------------------------------------------------
            SectionHeader { text: qsTr("Testing") }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Give me 1000 🍞 (testing)")
                onClicked: Zoo.grantCrumbs(1000)
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Hatch a blob (free)")
                onClicked: Zoo.debugHatch()
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Send oldest blob off 👋")
                enabled: Zoo.ownedBlobs.length > 0
                onClicked: Zoo.debugFarewell()
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Feed the Quest Beast 🦖")
                enabled: Zoo.ownedBlobs.length > 0
                onClicked: Zoo.debugBaitPredator()
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Trigger birthday 🎂")
                onClicked: Zoo.debugBirthday()
            }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Farewells, the beast and birthdays play out on the zoo page. Go home to watch.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Erase all data")
                onClicked: eraseRemorse.execute(qsTr("Erasing everything"), function () {
                    Zoo.resetAll()
                    pageStack.push(Qt.resolvedUrl("OnboardingPage.qml"))
                })
            }
            RemorsePopup { id: eraseRemorse }
            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("For trying things out. No judgement. Well, a little.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
            }

            // --- Reminders ---------------------------------------------------------------------
            SectionHeader { text: qsTr("Reminders") }

            TextSwitch {
                text: qsTr("Gentle daily reminder")
                description: qsTr("A soft nudge once a day. Off by default. The zoo waits for you, "
                                  + "it never nags.")
                checked: Zoo.reminderEnabled
                onCheckedChanged: if (checked !== Zoo.reminderEnabled) Zoo.reminderEnabled = checked
            }

            // --- About -------------------------------------------------------------------------
            SectionHeader { text: qsTr("About") }

            Item { width: parent.width; height: Theme.paddingMedium }

            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Zoo")
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("version %1").arg(Zoo.appVersion)
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            Item { width: parent.width; height: Theme.paddingSmall }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("A small, strange, living zoo. Do one little thing a day, keep your "
                           + "habits, and grow a collection of odd creatures you actually want to "
                           + "visit. Offline, private, and gentle. No shame, no timers built to "
                           + "stress you.")
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Item { width: parent.width; height: Theme.paddingSmall }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("© 2026 Nicolas Souveton, MIT licensed")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            BackgroundItem {
                width: parent.width
                Label {
                    x: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Source on GitHub")
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
                onClicked: Qt.openUrlExternally("https://github.com/nicosouv/harbour-zoo")
            }

            Item { width: parent.width; height: Theme.paddingLarge }

            // The signature.
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Made with ❤️ for Sailfish OS")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        VerticalScrollDecorator {}
    }
}
