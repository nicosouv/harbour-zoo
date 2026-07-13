import QtQuick 2.6
import Sailfish.Silica 1.0

// The Keeper's Almanac — the story's red thread. Chapters unlock at real milestones and reframe,
// slowly, that the zoo is a portrait of you keeping a promise to yourself. Opening the page counts
// as reading whatever is currently unlocked (it clears the gentle "a new page appeared" nudge).
Page {
    id: page
    allowedOrientations: Orientation.All

    // Snapshot once so marking chapters read below doesn't churn the list under us.
    property var chapters: []
    Component.onCompleted: {
        page.chapters = Zoo.almanacChapters()
        for (var i = 0; i < page.chapters.length; i++)
            if (page.chapters[i].unlocked && !page.chapters[i].read)
                Zoo.markChapterRead(page.chapters[i].id)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: qsTr("The Keeper's Almanac") }

            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap; text: qsTr("The zoo remembers. Read on when a page is ready.")
                color: Theme.secondaryHighlightColor; font.pixelSize: Theme.fontSizeExtraSmall; font.italic: true
            }

            Repeater {
                model: page.chapters
                delegate: Rectangle {
                    x: Theme.horizontalPageMargin
                    width: content.width - 2 * Theme.horizontalPageMargin
                    height: chapterCol.height + 2 * Theme.paddingLarge
                    radius: Theme.paddingMedium
                    color: Theme.rgba(Theme.highlightBackgroundColor, modelData.unlocked ? 0.16 : 0.05)
                    opacity: modelData.unlocked ? 1.0 : 0.45

                    Column {
                        id: chapterCol
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.paddingLarge; width: parent.width - 2 * Theme.paddingLarge
                        spacing: Theme.paddingSmall

                        Label {
                            text: qsTr("Chapter %1").arg(modelData.index)
                            color: Theme.highlightColor; font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        Label {
                            width: parent.width; wrapMode: Text.Wrap; text: modelData.title
                            color: Theme.primaryColor; font.pixelSize: Theme.fontSizeLarge
                        }
                        Label {
                            width: parent.width; wrapMode: Text.Wrap; text: modelData.body
                            color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
