import QtQuick 2.6
import Sailfish.Silica 1.0

// The "how am I doing" screen. Light: your Keeper rank and a handful of goofy stats. No walls of
// text, no shaming numbers — just a glance at how you've been playing.
Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("Keeper") }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                Label {
                    text: Zoo.keeperTitle
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    text: qsTr("Level %1 · %2 useful things done").arg(Zoo.keeperLevel).arg(Zoo.deeds)
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            // A tidy grid of stat chips.
            Grid {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                columns: 2
                spacing: Theme.paddingMedium

                Repeater {
                    model: [
                        { big: "🔥 " + Zoo.streak, label: qsTr("day streak") },
                        { big: "🥚 " + Zoo.ownedBlobs.length, label: qsTr("residents") },
                        { big: "🍞 " + Zoo.crumbs, label: qsTr("crumbs, unspent") },
                        { big: "📋 " + Zoo.habitsKeptToday, label: qsTr("habits kept today") }
                    ]
                    delegate: Rectangle {
                        width: (content.width - 2 * Theme.horizontalPageMargin - Theme.paddingMedium) / 2
                        height: Theme.itemSizeLarge
                        radius: Theme.paddingMedium
                        color: Theme.rgba(Theme.highlightBackgroundColor, 0.14)
                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.paddingSmall
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.big
                                color: Theme.primaryColor
                                font.pixelSize: Theme.fontSizeLarge
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Keep showing up and the title improves. That's the only KPI here.")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
        VerticalScrollDecorator {}
    }
}
