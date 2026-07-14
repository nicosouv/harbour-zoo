import QtQuick 2.6
import Sailfish.Silica 1.0

// A page for a single one-off task. Keeps Today uncluttered; keeps the tone unserious.
Page {
    id: page
    allowedOrientations: Orientation.All

    property string due: ""
    Component { id: dueDialog; DatePickerDialog { } }

    function save() {
        if (nameField.text.trim().length === 0) { pageStack.pop(); return }
        Zoo.addQuest(nameField.text, page.due)
        pageStack.pop()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("New quest") }

            Label {
                x: Theme.horizontalPageMargin; width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("A one-off thing. The blobs will pretend to be impressed.")
                color: Theme.secondaryColor; font.pixelSize: Theme.fontSizeExtraSmall
            }

            TextField {
                id: nameField; width: parent.width
                label: qsTr("The quest")
                placeholderText: qsTr("That thing you keep not doing")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"; EnterKey.onClicked: page.save()
            }

            ValueButton {
                label: qsTr("Deadline")
                value: page.due.length > 0 ? page.due : qsTr("none, live dangerously")
                onClicked: {
                    var d = pageStack.push(dueDialog)
                    d.accepted.connect(function () { page.due = Qt.formatDate(d.date, "yyyy-MM-dd") })
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Set it in motion")
                onClicked: page.save()
            }
        }
        VerticalScrollDecorator {}
    }
}
