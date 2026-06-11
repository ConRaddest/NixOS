import QtQuick

// Reusable keyboard-driven search/list component used by the launcher,
// clipboard picker, and future search surfaces.
Rectangle {
    id: menu

    required property var shell

    property string query: ""
    property var items: []
    property string searchIcon: "󰍉"
    property bool focusWhenVisible: false

    // Callbacks supplied by the caller.
    property var itemText: function (item) {
        return item.displayName || item.name || item.display || "";
    }
    property var itemIcon: function (item) {
        return item.icon || "";
    }
    property var itemIconPath: function (item) {
        return item.iconPath || "";
    }
    property var itemCommand: function (item) {
        return "";
    }
    property var itemCategory: function (item) {
        return "";
    }
    property var highlightedText: function (text) {
        return String(text);
    }
    property var italicPredicate: function (item) {
        return false;
    }

    // Confirm overlay support.
    property bool confirmVisible: false
    property string confirmText: "Confirm"
    property string confirmSelection: "confirm"

    property alias inputItem: input
    property alias listItem: list

    signal queryEdited(string query)
    signal accepted(var item)
    signal back
    signal clearRequested
    signal confirmAccepted
    signal confirmCancelled
    signal confirmSelectionEdited(string selection)

    color: shell.base

    onVisibleChanged: if (visible && focusWhenVisible)
        input.forceActiveFocus()
    onItemsChanged: list.currentIndex = 0

    // ─── Search bar ───────────────────────────────────────────────────────────
    Item {
        id: searchBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 56

        Text {
            id: searchIconText
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: menu.searchIcon
            color: menu.shell.accent
            font.family: menu.shell.monoFont
            font.pixelSize: 20
        }

        // Placeholder overlaid on the input
        Text {
            anchors.left: searchIconText.right
            anchors.leftMargin: 12
            anchors.right: escPill.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "Search apps / the web · do math"
            color: menu.shell.muted
            font.family: menu.shell.monoFont
            font.pixelSize: 14
            visible: input.text === ""
            elide: Text.ElideRight
        }

        TextInput {
            id: input
            anchors.left: searchIconText.right
            anchors.leftMargin: 12
            anchors.right: escPill.left
            anchors.rightMargin: 12
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: TextInput.AlignVCenter
            focus: menu.focusWhenVisible
            text: menu.query
            color: menu.shell.text
            selectionColor: menu.shell.overlay
            selectedTextColor: menu.shell.text
            font.family: menu.shell.monoFont
            font.pixelSize: 14

            onTextChanged: menu.queryEdited(text)

            Keys.onEscapePressed: menu.back()
            Keys.onDownPressed: {
                if (!menu.confirmVisible)
                    list.currentIndex = Math.min(list.currentIndex + 1, menu.items.length - 1);
            }
            Keys.onUpPressed: {
                if (!menu.confirmVisible)
                    list.currentIndex = Math.max(list.currentIndex - 1, 0);
            }
            Keys.onLeftPressed: {
                if (menu.confirmVisible)
                    menu.confirmSelectionEdited("cancel");
            }
            Keys.onRightPressed: {
                if (menu.confirmVisible)
                    menu.confirmSelectionEdited("confirm");
            }
            Keys.onPressed: event => {
                if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_C) {
                    input.text = "";
                    menu.clearRequested();
                    event.accepted = true;
                }
            }
            Keys.onReturnPressed: {
                if (menu.confirmVisible) {
                    if (menu.confirmSelection === "confirm")
                        menu.confirmAccepted();
                    else
                        menu.confirmCancelled();
                } else if (menu.items.length > 0 && list.currentIndex >= 0) {
                    menu.accepted(menu.items[list.currentIndex]);
                }
            }
        }

        Rectangle {
            id: escPill
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: escLabel.implicitWidth + 16
            height: 22
            radius: 5
            color: "transparent"
            border.color: menu.shell.border
            border.width: 1

            Text {
                id: escLabel
                anchors.centerIn: parent
                text: "esc"
                color: menu.shell.muted
                font.family: menu.shell.monoFont
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: menu.back()
            }
        }

        // Bottom divider
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: menu.shell.border
        }
    }

    // ─── List ─────────────────────────────────────────────────────────────────
    ListView {
        id: list
        anchors.top: searchBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        model: menu.items
        currentIndex: 0

        delegate: Item {
            required property var modelData
            required property int index

            readonly property bool isCurrent: ListView.isCurrentItem

            width: list.width
            height: 54

            // Selected row background
            Rectangle {
                anchors.fill: parent
                color: parent.isCurrent ? menu.shell.overlay : "transparent"
                opacity: 0.6
            }

            // Left accent stripe
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                radius: 2
                color: menu.shell.accent
                visible: parent.isCurrent
            }

            // ── Row content ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                // Icon badge
                Rectangle {
                    id: iconBadge
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 9
                    color: menu.shell.surface

                    Text {
                        anchors.centerIn: parent
                        visible: !menu.itemIconPath(modelData)
                        text: menu.itemIcon(modelData)
                        color: menu.shell.accent
                        font.family: menu.shell.monoFont
                        font.pixelSize: 17
                        font.italic: menu.italicPredicate(modelData)
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: !!menu.itemIconPath(modelData)
                        source: menu.itemIconPath(modelData)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }

                // Category label — fixed width on the far right
                Text {
                    id: categoryLabel
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: menu.itemCategory(modelData)
                    color: isCurrent ? menu.shell.accent : menu.shell.muted
                    font.family: menu.shell.monoFont
                    font.pixelSize: 13
                    font.weight: isCurrent ? Font.Bold : Font.Normal
                    width: 72
                    horizontalAlignment: Text.AlignRight
                    visible: text !== ""
                }

                // Command hint — just left of category
                Text {
                    id: commandLabel
                    anchors.right: categoryLabel.visible ? categoryLabel.left : parent.right
                    anchors.rightMargin: categoryLabel.visible ? 16 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: menu.itemCommand(modelData)
                    color: menu.shell.muted
                    font.family: menu.shell.monoFont
                    font.pixelSize: 13
                    visible: text !== ""
                }

                // App name — fills remaining space between badge and command
                Text {
                    anchors.left: iconBadge.right
                    anchors.leftMargin: 14
                    anchors.right: commandLabel.visible ? commandLabel.left : (categoryLabel.visible ? categoryLabel.left : parent.right)
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: menu.highlightedText(menu.itemText(modelData))
                    textFormat: Text.RichText
                    color: menu.shell.text
                    font.family: menu.shell.monoFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    font.italic: menu.italicPredicate(modelData)
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: list.currentIndex = index
                onClicked: menu.accepted(modelData)
            }
        }
    }

    // ─── Confirm overlay ──────────────────────────────────────────────────────
    component ConfirmButton: Rectangle {
        id: button

        required property var shell
        property string text: ""
        property bool selected: false
        signal clicked

        width: 110
        height: 32
        radius: 6
        color: selected || mouse.containsMouse ? shell.overlay : "transparent"
        border.color: selected || mouse.containsMouse ? shell.accent : shell.border
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: button.text
            color: button.shell.text
            font.family: menu.shell.monoFont
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: menu.confirmVisible
        color: menu.shell.base
        opacity: 0.96

        Column {
            anchors.centerIn: parent
            spacing: 18

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Are you sure?"
                color: menu.shell.text
                font.family: menu.shell.monoFont
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                ConfirmButton {
                    shell: menu.shell
                    text: "Cancel"
                    selected: menu.confirmSelection === "cancel"
                    onClicked: menu.confirmCancelled()
                }

                ConfirmButton {
                    shell: menu.shell
                    text: menu.confirmText
                    selected: menu.confirmSelection === "confirm"
                    onClicked: menu.confirmAccepted()
                }
            }
        }
    }
}
