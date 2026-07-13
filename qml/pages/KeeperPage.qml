import QtQuick 2.6
import Sailfish.Silica 1.0

// "How am I doing" — rank, a small activity graph, quick stats, and badges earned by playing.
Page {
    id: page
    allowedOrientations: Orientation.All

    function maxOf(arr) { var m = 1; for (var i = 0; i < arr.length; i++) if (arr[i] > m) m = arr[i]; return m; }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("Keeper") }

            Column {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                Label { text: Zoo.keeperTitle; color: Theme.highlightColor; font.pixelSize: Theme.fontSizeExtraLarge }
                Label { text: qsTr("Level %1 · %2 useful things done").arg(Zoo.keeperLevel).arg(Zoo.deeds)
                        color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall }
                Item { width: 1; height: Theme.paddingSmall }
                Label {
                    width: parent.width; visible: Zoo.reflection.length > 0; wrapMode: Text.Wrap
                    text: Zoo.reflection; color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraSmall; font.italic: true
                }
                Label {
                    width: parent.width; visible: Zoo.ownedBlobs.length > 0; wrapMode: Text.Wrap
                    text: qsTr("Every resident is a day you looked after yourself. The habits are the point; the zoo just makes it visible.")
                    color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeTiny
                }
            }

            // --- The story so far -------------------------------------------------------------
            SectionHeader { text: qsTr("The Keeper's Almanac") }
            BackgroundItem {
                width: parent.width; height: Theme.itemSizeSmall
                onClicked: pageStack.push(Qt.resolvedUrl("AlmanacPage.qml"))
                Label {
                    anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                    width: parent.width - 2 * Theme.horizontalPageMargin - Theme.iconSizeSmall
                    wrapMode: Text.Wrap
                    text: Zoo.hasUnreadAlmanac ? qsTr("A new page is waiting to be read.")
                                               : qsTr("The story of the zoo, and of you.")
                    color: Zoo.hasUnreadAlmanac ? Theme.highlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
                Image {
                    source: "image://theme/icon-m-right"
                    anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin; verticalCenter: parent.verticalCenter }
                }
            }

            // --- Last 7 days activity graph ---------------------------------------------------
            SectionHeader { text: qsTr("Last 7 days") }
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: Theme.itemSizeLarge
                spacing: Theme.paddingSmall
                Repeater {
                    model: Zoo.activity7
                    delegate: Item {
                        width: (content.width - 2 * Theme.horizontalPageMargin - 6 * Theme.paddingSmall) / 7
                        height: parent.height
                        Rectangle {
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: parent.width * 0.7
                            height: Math.max(2, (modelData / page.maxOf(Zoo.activity7)) * (parent.height - Theme.paddingLarge))
                            radius: Theme.paddingSmall / 2
                            color: index === 6 ? Theme.highlightColor : Theme.rgba(Theme.highlightColor, 0.4)
                        }
                        Label {
                            anchors { top: parent.bottom; horizontalCenter: parent.horizontalCenter; topMargin: -Theme.paddingLarge }
                            text: modelData; color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeTiny
                        }
                    }
                }
            }

            // --- Quick stats ------------------------------------------------------------------
            Grid {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                columns: 2; spacing: Theme.paddingMedium
                Repeater {
                    model: [
                        { big: "🔥 " + Zoo.streak, label: qsTr("day streak") },
                        { big: "🥚 " + Zoo.ownedBlobs.length, label: qsTr("residents") },
                        { big: "🍞 " + Zoo.crumbs, label: qsTr("crumbs, unspent") },
                        { big: "📋 " + Zoo.habitsKeptToday, label: qsTr("habits kept today") },
                        { big: "📅 " + Zoo.weekDeeds, label: qsTr("useful things this week") },
                        { big: "🗓️ " + Zoo.monthDeeds, label: qsTr("this month") }
                    ]
                    delegate: Rectangle {
                        width: (content.width - 2 * Theme.horizontalPageMargin - Theme.paddingMedium) / 2
                        height: Theme.itemSizeMedium
                        radius: Theme.paddingMedium
                        color: Theme.rgba(Theme.highlightBackgroundColor, 0.14)
                        Column {
                            anchors.centerIn: parent; spacing: 2
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.big
                                    color: Theme.primaryColor; font.pixelSize: Theme.fontSizeLarge }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label
                                    color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall }
                        }
                    }
                }
            }

            // --- Badges -----------------------------------------------------------------------
            SectionHeader { text: qsTr("Badges") }
            Grid {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                columns: 2; spacing: Theme.paddingMedium
                Repeater {
                    model: Zoo.badges
                    delegate: Rectangle {
                        width: (content.width - 2 * Theme.horizontalPageMargin - Theme.paddingMedium) / 2
                        height: badgeCol.height + 2 * Theme.paddingMedium
                        radius: Theme.paddingMedium
                        color: Theme.rgba(Theme.highlightBackgroundColor, modelData.earned ? 0.20 : 0.06)
                        opacity: modelData.earned ? 1.0 : 0.5
                        Row {
                            id: badgeCol
                            anchors.centerIn: parent
                            width: parent.width - 2 * Theme.paddingMedium
                            spacing: Theme.paddingSmall
                            Label { text: modelData.emoji; font.pixelSize: Theme.fontSizeLarge
                                    anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                width: parent.width - Theme.fontSizeLarge - Theme.paddingSmall
                                anchors.verticalCenter: parent.verticalCenter
                                Label { width: parent.width; text: modelData.name; truncationMode: TruncationMode.Fade
                                        color: modelData.earned ? Theme.primaryColor : Theme.secondaryColor
                                        font.pixelSize: Theme.fontSizeExtraSmall }
                                Label { width: parent.width; wrapMode: Text.Wrap; text: modelData.desc
                                        color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeTiny }
                            }
                        }
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
