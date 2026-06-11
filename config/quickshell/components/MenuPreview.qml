import QtQuick

// Shared searchable list + preview picker used by wallpaper, screenshot, and
// clipboard browsers. The left pane can be resized by dragging the divider.
Rectangle {
    id: picker

    required property var shell

    property string searchIcon: "󰍉"
    property string query: ""
    property var items: []
    property int listWidth: 280

    property var itemText: function (item) {
        return item.display || item.name || "";
    }
    property var itemIcon: function (item) {
        return item.icon || "󰆒";
    }
    property var itemMatches: function (item, q) {
        return picker.itemText(item).toLowerCase().includes(q);
    }
    property var highlightedText: function (text) {
        return picker.highlighted(text);
    }
    property var isImage: function (item) {
        return true;
    }
    property var imageSource: function (item) {
        return item && item.path ? "file://" + item.path : "";
    }
    property var previewText: function (item) {
        return item ? picker.itemText(item) : "";
    }

    property alias listItem: list
    property alias inputItem: input
    readonly property var filteredItems: getFilteredItems()
    property var currentItem: null

    signal accepted(var item)
    signal selectedItemChanged(var item)
    signal queryEdited(string query)
    signal back

    color: shell.base

    onItemsChanged: Qt.callLater(resetSelection)
    onQueryChanged: Qt.callLater(resetSelection)

    function itemAtIndex(index) {
        return index >= 0 && index < filteredItems.length ? filteredItems[index] : null;
    }

    function syncSelection() {
        const item = itemAtIndex(list.currentIndex);
        currentItem = item;
        selectedItemChanged(item);
    }

    function resetSelection() {
        list.currentIndex = filteredItems.length > 0 ? 0 : -1;
        syncSelection();
    }

    function getFilteredItems() {
        const q = query.trim().toLowerCase();
        if (q === "")
            return items;
        return items.filter(item => itemMatches(item, q));
    }

    function highlighted(text) {
        const value = String(text);
        const q = query.trim();
        if (q === "")
            return escapeHtml(value);

        const lowerValue = value.toLowerCase();
        const lowerQuery = q.toLowerCase();

        const matched = new Array(value.length).fill(false);
        let qi = 0;
        for (let si = 0; si < lowerValue.length && qi < lowerQuery.length; si++) {
            if (lowerValue[si] === lowerQuery[qi]) {
                matched[si] = true;
                qi++;
            }
        }
        if (qi < lowerQuery.length)
            return escapeHtml(value);

        let result = "";
        let inSpan = false;
        for (let i = 0; i < value.length; i++) {
            if (matched[i] && !inSpan) {
                result += "<span style=\"color: " + shell.accent + "\">";
                inSpan = true;
            } else if (!matched[i] && inSpan) {
                result += "</span>";
                inSpan = false;
            }
            result += escapeHtml(value[i]);
        }
        if (inSpan)
            result += "</span>";
        return result;
    }

    function escapeHtml(text) {
        return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
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
            text: picker.searchIcon
            color: picker.shell.muted
            font.family: picker.shell.monoFont
            font.pixelSize: 16
        }

        Text {
            anchors.left: searchIconText.right
            anchors.leftMargin: 12
            anchors.right: escPill.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "Search..."
            color: picker.shell.muted
            font.family: picker.shell.monoFont
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
            text: picker.query
            color: picker.shell.text
            selectionColor: picker.shell.overlay
            selectedTextColor: picker.shell.text
            font.family: picker.shell.monoFont
            font.pixelSize: 14

            onTextChanged: picker.queryEdited(text)

            Keys.onEscapePressed: picker.back()
            Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, picker.filteredItems.length - 1)
            Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
            Keys.onReturnPressed: if (picker.currentItem)
                picker.accepted(picker.currentItem)
            Keys.onPressed: event => {
                if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_C) {
                    input.text = "";
                    picker.queryEdited("");
                    event.accepted = true;
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
            border.color: picker.shell.border
            border.width: 1

            Text {
                id: escLabel
                anchors.centerIn: parent
                text: "esc"
                color: picker.shell.muted
                font.family: picker.shell.monoFont
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: picker.back()
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: picker.shell.border
        }
    }

    // ─── Body: list + divider + preview ──────────────────────────────────────
    Item {
        id: body
        anchors.top: searchBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // ── Left pane: item list ──────────────────────────────────────────────
        Item {
            id: leftPane
            width: Math.max(160, Math.min(picker.listWidth, body.width - 180))
            height: parent.height
            clip: true

            ListView {
                id: list
                anchors.fill: parent
                model: picker.filteredItems
                currentIndex: picker.filteredItems.length > 0 ? 0 : -1
                onCurrentIndexChanged: picker.syncSelection()

                delegate: Item {
                    required property var modelData
                    required property int index

                    readonly property bool isCurrent: ListView.isCurrentItem

                    width: leftPane.width
                    height: 44

                    Rectangle {
                        x: 0
                        y: 0
                        width: leftPane.width
                        height: parent.height
                        color: parent.isCurrent ? picker.shell.overlay : "transparent"
                        opacity: 0.6
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        radius: 2
                        color: picker.shell.accent
                        visible: parent.isCurrent
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            width: 18
                            text: picker.itemIcon(modelData)
                            color: picker.shell.accent
                            font.family: picker.shell.monoFont
                            font.pixelSize: 15
                            horizontalAlignment: Text.AlignHCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: picker.highlightedText(picker.itemText(modelData))
                            textFormat: Text.RichText
                            color: isCurrent ? picker.shell.text : picker.shell.subtext
                            font.family: picker.shell.monoFont
                            font.pixelSize: 14
                            font.weight: isCurrent ? Font.Bold : Font.Normal
                            elide: Text.ElideRight
                            width: leftPane.width - 50
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: {
                            list.currentIndex = index;
                            picker.accepted(modelData);
                        }
                    }
                }
            }
        }

        // ── Draggable divider ─────────────────────────────────────────────────
        Item {
            id: divider
            x: leftPane.width
            width: 9
            height: parent.height

            Rectangle {
                x: 0
                y: 0
                width: 1
                height: parent.height
                color: dividerMouse.containsMouse || dividerMouse.pressed ? picker.shell.accent : picker.shell.border
                opacity: dividerMouse.containsMouse || dividerMouse.pressed ? 1 : 0.6
            }

            property real dragStartX: 0
            property real dragStartWidth: 0

            MouseArea {
                id: dividerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SplitHCursor
                onPressed: mouse => {
                    const p = mapToItem(body, mouse.x, mouse.y);
                    divider.dragStartX = p.x;
                    divider.dragStartWidth = picker.listWidth;
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    const p = mapToItem(body, mouse.x, mouse.y);
                    picker.listWidth = Math.max(160, Math.min(divider.dragStartWidth + (p.x - divider.dragStartX), body.width - 180));
                }
            }
        }

        // ── Right pane: preview ───────────────────────────────────────────────
        Item {
            id: rightPane
            x: leftPane.width + divider.width
            width: body.width - leftPane.width - divider.width
            height: parent.height

            Image {
                anchors.fill: parent
                anchors.margins: 12
                visible: picker.currentItem && picker.isImage(picker.currentItem)
                source: picker.currentItem ? picker.imageSource(picker.currentItem) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                visible: !picker.currentItem || !picker.isImage(picker.currentItem)
                contentWidth: Math.max(width, textPreview.paintedWidth)
                contentHeight: textPreview.paintedHeight
                clip: true

                Text {
                    id: textPreview
                    width: parent.width
                    text: picker.currentItem ? picker.previewText(picker.currentItem) : ""
                    color: picker.shell.text
                    font.family: picker.shell.monoFont
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
