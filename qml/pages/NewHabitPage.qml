import QtQuick 2.6
import Sailfish.Silica 1.0

// A whole page just to add a habit — so Today stays a glance, not a form. Dry, unserious copy.
Page {
    id: page
    allowedOrientations: Orientation.All

    readonly property string kind: kindCombo.currentIndex === 1 ? "bad" : "good"

    function save() {
        if (nameField.text.trim().length === 0) { pageStack.pop(); return }
        Zoo.addHabit(nameField.text, Math.round(targetSlider.value), page.kind,
                     cueField.text, replacementField.text, tolerateSwitch.checked)
        pageStack.pop()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("New habit") }

            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("A small promise to future-you. Future-you is unreliable, but we press on regardless.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
            }

            TextField {
                id: nameField; width: parent.width
                label: qsTr("The habit")
                placeholderText: qsTr("Something you'll actually do. In theory.")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"; EnterKey.onClicked: cueField.focus = true
            }

            ComboBox {
                id: kindCombo
                width: parent.width
                label: qsTr("Sort")
                menu: ContextMenu {
                    MenuItem { text: qsTr("One to keep") }
                    MenuItem { text: qsTr("One to quit") }
                }
            }

            // The anchor — the one lever that actually works. Applies to good and bad alike.
            TextField {
                id: cueField; width: parent.width
                label: qsTr("When, exactly?")
                placeholderText: qsTr("after my morning coffee (anchors work; willpower sulks)")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: page.save()
            }

            Slider {
                id: targetSlider
                visible: page.kind === "good"
                width: parent.width
                minimumValue: 1; maximumValue: 8; stepSize: 1; value: 1
                label: qsTr("How many times a day?")
                valueText: value
            }

            // For a bad habit: the swap (same reward) and a bounded amnesty.
            TextField {
                id: replacementField; width: parent.width
                visible: page.kind === "bad"
                label: qsTr("Do this instead")
                placeholderText: qsTr("same payoff, fewer regrets")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: page.save()
            }
            TextSwitch {
                id: tolerateSwitch
                visible: page.kind === "bad"
                text: qsTr("Tolerate it, for now")
                description: qsTr("Slips won't sour the zoo. Two weeks' grace, then it quietly counts again.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Add it to the pile")
                onClicked: page.save()
            }
        }
        VerticalScrollDecorator {}
    }
}
