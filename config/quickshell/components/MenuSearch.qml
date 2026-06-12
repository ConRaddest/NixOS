import QtQuick

// Reusable keyboard-driven search/list component used by the launcher,
// clipboard picker, and future search surfaces.
Rectangle {
    id: menu

    required property var shell

    property string query: ""
    property var items: []
    property string searchIcon: "󰍉"
    property string placeholderText: "Search apps / the web · do math"
    property string rightPillText: "esc"
    property bool rightPillBorder: true
    property string headerCommandText: ""
    property string headerCategoryText: ""
    property bool focusWhenVisible: false
    property bool terminateKeyEnabled: false
    property bool resetIndexOnItemsChanged: true
    property bool hoverSelectEnabled: true
    property int viewportGeneration: 0

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
    property string confirmTitle: "Are you sure?"
    property string confirmSelection: "confirm"

    property alias inputItem: input
    property alias listItem: list

    signal queryEdited(string query)
    signal accepted(var item)
    signal back
    signal clearRequested
    signal terminateRequested(var item)
    signal dotPressed
    signal confirmAccepted
    signal confirmCancelled
    signal confirmSelectionEdited(string selection)

    color: shell.base

    onVisibleChanged: if (visible && focusWhenVisible)
        input.forceActiveFocus()
    onItemsChanged: if (resetIndexOnItemsChanged)
        list.currentIndex = 0

    function moveSelection(delta) {
        if (items.length === 0)
            return;

        viewportGeneration++;
        list.currentIndex = Math.max(0, Math.min(list.currentIndex + delta, items.length - 1));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

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
            anchors.right: headerCategoryLabel.visible ? headerCommandLabel.left : escPill.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: menu.placeholderText
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
            anchors.right: headerCategoryLabel.visible ? headerCommandLabel.left : escPill.left
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
                    menu.moveSelection(1);
            }
            Keys.onUpPressed: {
                if (!menu.confirmVisible)
                    menu.moveSelection(-1);
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
                } else if (menu.terminateKeyEnabled && event.modifiers === Qt.NoModifier && event.key === Qt.Key_T && menu.items.length > 0 && list.currentIndex >= 0) {
                    menu.terminateRequested(menu.items[list.currentIndex]);
                    event.accepted = true;
                } else if (event.modifiers === Qt.NoModifier && event.key === Qt.Key_Period) {
                    menu.dotPressed();
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

        Text {
            id: headerCategoryLabel
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: menu.headerCategoryText
            color: menu.shell.muted
            font.family: menu.shell.monoFont
            font.pixelSize: 13
            width: 72
            horizontalAlignment: Text.AlignRight
            visible: text !== ""
        }

        Text {
            id: headerCommandLabel
            anchors.right: headerCategoryLabel.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: menu.headerCommandText
            color: menu.shell.muted
            font.family: menu.shell.monoFont
            font.pixelSize: 13
            visible: text !== ""
        }

        Rectangle {
            id: escPill
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: escLabel.implicitWidth + (menu.rightPillBorder ? 16 : 0)
            height: 22
            radius: 5
            color: "transparent"
            border.color: menu.rightPillBorder ? menu.shell.border : "transparent"
            border.width: menu.rightPillBorder ? 1 : 0
            visible: !headerCategoryLabel.visible

            Text {
                id: escLabel
                anchors.centerIn: parent
                text: menu.rightPillText
                color: menu.shell.muted
                font.family: menu.shell.monoFont
                font.pixelSize: menu.rightPillBorder ? 12 : 13
            }

            MouseArea {
                anchors.fill: parent
                enabled: menu.rightPillText === "esc"
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
                hoverEnabled: menu.hoverSelectEnabled
                onEntered: if (menu.hoverSelectEnabled)
                    list.currentIndex = index
                onClicked: {
                    list.currentIndex = index;
                    menu.accepted(modelData);
                }
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

        width: 140
        height: 42
        radius: 8
        color: selected || mouse.containsMouse ? shell.overlay : "transparent"
        border.color: selected || mouse.containsMouse ? shell.accent : shell.border
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: button.text
            color: button.shell.text
            font.family: menu.shell.monoFont
            font.pixelSize: 15
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
            spacing: 20

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: menu.confirmTitle
                color: menu.shell.text
                font.family: menu.shell.monoFont
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

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
