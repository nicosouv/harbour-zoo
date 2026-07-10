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

            // --- Reminders ---------------------------------------------------------------------
            SectionHeader { text: qsTr("Reminders") }

            TextSwitch {
                text: qsTr("Gentle daily reminder")
                description: qsTr("A soft nudge once a day. Off by default — the zoo waits for you, "
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
                           + "visit. Offline, private, and gentle — no shame, no timers built to "
                           + "stress you.")
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Item { width: parent.width; height: Theme.paddingSmall }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("© 2026 Nicolas Souveton — MIT licensed")
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
