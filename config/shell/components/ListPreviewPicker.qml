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

  property var itemText: function(item) { return item.display || item.name || "" }
  property var itemIcon: function(item) { return item.icon || "󰆒" }
  property var itemMatches: function(item, q) { return picker.itemText(item).toLowerCase().includes(q) }
  property var highlightedText: function(text) { return picker.highlighted(text) }
  property var isImage: function(item) { return true }
  property var imageSource: function(item) { return item && item.path ? "file://" + item.path : "" }
  property var previewText: function(item) { return item ? picker.itemText(item) : "" }

  property alias listItem: list
  property alias inputItem: input
  readonly property var filteredItems: getFilteredItems()
  readonly property var currentItem: filteredItems.length > 0 && list.currentIndex >= 0 ? filteredItems[list.currentIndex] : null

  signal accepted(var item)
  signal selectedItemChanged(var item)
  signal queryEdited(string query)
  signal back()

  color: shell.bg

  onItemsChanged: Qt.callLater(resetSelection)
  onQueryChanged: Qt.callLater(resetSelection)

  function resetSelection() {
    list.currentIndex = filteredItems.length > 0 ? 0 : -1
    selectedItemChanged(currentItem)
  }

  function getFilteredItems() {
    const q = query.trim().toLowerCase()
    if (q === "") return items
    return items.filter(item => itemMatches(item, q))
  }

  function highlighted(text) {
    const value = String(text)
    const q = query.trim()
    if (q === "") return escapeHtml(value)
    const lowerValue = value.toLowerCase()
    const lowerQuery = q.toLowerCase()
    let result = ""
    let pos = 0
    let match = lowerValue.indexOf(lowerQuery, pos)
    while (match !== -1) {
      result += escapeHtml(value.slice(pos, match))
      result += "<span style=\"color: " + shell.accent + "\">" + escapeHtml(value.slice(match, match + q.length)) + "</span>"
      pos = match + q.length
      match = lowerValue.indexOf(lowerQuery, pos)
    }
    return result + escapeHtml(value.slice(pos))
  }

  function escapeHtml(text) {
    return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  Column {
    anchors.fill: parent
    anchors.margins: 10
    spacing: 10

    Rectangle {
      width: parent.width
      height: 42
      radius: 5
      color: "transparent"
      border.color: picker.shell.surface
      border.width: 2

      Text {
        id: searchIconItem
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        text: picker.searchIcon
        color: picker.shell.accent
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
      }

      TextInput {
        id: input
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: searchIconItem.right
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        anchors.leftMargin: 10
        leftPadding: 0
        rightPadding: 10
        verticalAlignment: TextInput.AlignVCenter
        text: picker.query
        color: picker.shell.fg
        selectionColor: picker.shell.accent
        selectedTextColor: picker.shell.bg
        font.family: "monospace"
        font.pixelSize: 15
        font.weight: Font.Bold

        onTextChanged: picker.queryEdited(text)

        Keys.onEscapePressed: picker.back()
        Keys.onDownPressed: list.currentIndex = Math.min(list.currentIndex + 1, picker.filteredItems.length - 1)
        Keys.onUpPressed: list.currentIndex = Math.max(list.currentIndex - 1, 0)
        Keys.onReturnPressed: if (picker.currentItem) picker.accepted(picker.currentItem)
        Keys.onPressed: event => {
          if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_C) {
            input.text = ""
            picker.queryEdited("")
            event.accepted = true
          }
        }
      }
    }

    Item {
      id: body
      width: parent.width
      height: parent.height - 42 - parent.spacing

      Rectangle {
        id: leftPane
        width: Math.max(160, Math.min(picker.listWidth, body.width - 180))
        height: parent.height
        radius: 5
        color: "transparent"
        border.color: picker.shell.surface
        border.width: 2

        ListView {
          id: list
          anchors.fill: parent
          anchors.margins: 6
          clip: true
          model: picker.filteredItems
          currentIndex: picker.filteredItems.length > 0 ? 0 : -1
          onCurrentIndexChanged: picker.selectedItemChanged(picker.currentItem)

          delegate: Rectangle {
            required property var modelData
            required property int index

            width: ListView.view.width
            height: 28
            color: ListView.isCurrentItem ? picker.shell.hover : "transparent"

            Row {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 4
              spacing: 10

              Text {
                width: 18
                text: picker.itemIcon(modelData)
                color: picker.shell.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
              }

              Text {
                text: picker.highlightedText(picker.itemText(modelData))
                textFormat: Text.RichText
                color: ListView.isCurrentItem ? picker.shell.fg : "#b7bbcc"
                font.family: "monospace"
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
                width: leftPane.width - 44
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: list.currentIndex = index
              onClicked: {
                list.currentIndex = index
                picker.accepted(modelData)
              }
            }
          }
        }
      }

      Rectangle {
        id: divider
        x: leftPane.width + 2
        width: 6
        height: parent.height
        color: dividerMouse.containsMouse || dividerMouse.pressed ? picker.shell.accent : "transparent"
        opacity: 0.65

        property real dragStartX: 0
        property real dragStartWidth: 0

        MouseArea {
          id: dividerMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.SplitHCursor
          onPressed: mouse => {
            const p = mapToItem(body, mouse.x, mouse.y)
            divider.dragStartX = p.x
            divider.dragStartWidth = picker.listWidth
          }
          onPositionChanged: mouse => {
            if (!pressed) return
            const p = mapToItem(body, mouse.x, mouse.y)
            picker.listWidth = Math.max(160, Math.min(divider.dragStartWidth + (p.x - divider.dragStartX), body.width - 180))
          }
        }
      }

      Rectangle {
        id: rightPane
        x: leftPane.width + 10
        width: body.width - leftPane.width - 10
        height: parent.height
        radius: 5
        color: "transparent"
        border.color: picker.shell.surface
        border.width: 2

        Image {
          anchors.fill: parent
          anchors.margins: 8
          visible: picker.currentItem && picker.isImage(picker.currentItem)
          source: picker.currentItem ? picker.imageSource(picker.currentItem) : ""
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          cache: false
        }

        Flickable {
          anchors.fill: parent
          anchors.margins: 8
          visible: !picker.currentItem || !picker.isImage(picker.currentItem)
          contentWidth: Math.max(width, textPreview.paintedWidth)
          contentHeight: textPreview.paintedHeight
          clip: true

          Text {
            id: textPreview
            width: parent.width
            text: picker.currentItem ? picker.previewText(picker.currentItem) : ""
            color: picker.shell.fg
            font.family: "monospace"
            font.pixelSize: 14
            wrapMode: Text.Wrap
          }
        }
      }
    }
  }
}
