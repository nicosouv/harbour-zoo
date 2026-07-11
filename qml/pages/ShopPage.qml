import QtQuick 2.6
import Sailfish.Silica 1.0

// Spend Crumbs on objects for the zoo. Some objects also arrive for free at milestones (see the
// note below). This is where "doing useful things" cashes out into a nicer habitat.
Page {
    id: page
    allowedOrientations: Orientation.All

    function decoEmoji(id) {
        if (id === "rock") return "🪨";
        if (id === "fern") return "🌿";
        if (id === "sign") return "🪧";
        if (id === "lamp") return "💡";
        if (id === "pond") return "🌊";
        if (id === "arch") return "🏛️";
        return "✦";
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Shop")
                description: qsTr("%1 crumbs to your name").arg(Zoo.crumbs)
            }

            Repeater {
                model: Zoo.shopItems
                delegate: ListItem {
                    width: content.width
                    contentHeight: Theme.itemSizeMedium

                    Label {
                        id: emoji
                        anchors { left: parent.left; leftMargin: Theme.horizontalPageMargin
                                  verticalCenter: parent.verticalCenter }
                        text: page.decoEmoji(modelData.id)
                        font.pixelSize: Theme.fontSizeLarge
                    }
                    Column {
                        anchors { left: emoji.right; leftMargin: Theme.paddingMedium
                                  right: buyBtn.left; rightMargin: Theme.paddingMedium
                                  verticalCenter: parent.verticalCenter }
                        Label {
                            text: modelData.name
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            color: modelData.owned ? Theme.secondaryColor : Theme.primaryColor
                        }
                        Label {
                            text: modelData.owned ? qsTr("In your zoo")
                                                  : qsTr("%1 crumbs").arg(modelData.cost)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }
                    Button {
                        id: buyBtn
                        anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin
                                  verticalCenter: parent.verticalCenter }
                        text: modelData.owned ? qsTr("Owned") : qsTr("Buy")
                        enabled: !modelData.owned && Zoo.crumbs >= modelData.cost
                        onClicked: Zoo.buyObject(modelData.id)
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Some objects turn up for free when you hit a milestone — your first "
                           + "hatch, a week of habits, that sort of thing. No need to thank us.")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
        VerticalScrollDecorator {}
    }
}
