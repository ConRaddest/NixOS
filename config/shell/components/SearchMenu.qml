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

  // Optional behavior hooks supplied by the caller.
  property var itemText: function(item) { return item.displayName || item.name || item.display || "" }
  property var itemIcon: function(item) { return item.icon || "" }
  property var itemIconPath: function(item) { return item.iconPath || "" }
  property var highlightedText: function(text) { return String(text) }
  property var italicPredicate: function(item) { return false }

  // Optional confirm overlay support.
  property bool confirmVisible: false
  property string confirmText: "Confirm"
  property string confirmSelection: "confirm"

  property alias inputItem: input
  property alias listItem: list

  signal queryEdited(string query)
  signal accepted(var item)
  signal back()
  signal clearRequested()
  signal confirmAccepted()
  signal confirmCancelled()
  signal confirmSelectionEdited(string selection)

  color: shell.bg

  onVisibleChanged: if (visible && focusWhenVisible) input.forceActiveFocus()
  onItemsChanged: list.currentIndex = 0

  component ConfirmButton: Rectangle {
    id: button

    required property var shell
    property string text: ""
    property bool selected: false
    signal clicked()

    width: 110
    height: 32
    color: selected || mouse.containsMouse ? shell.selection : "transparent"
    border.color: selected || mouse.containsMouse ? shell.accent : shell.surface
    border.width: 2

    Text {
      anchors.centerIn: parent
      text: button.text
      color: button.shell.fg
      font.family: "monospace"
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

  Column {
    anchors.fill: parent
    anchors.margins: 10
    spacing: 10

    Rectangle {
      width: parent.width
      height: 42
      radius: 5
      color: "transparent"
      border.color: menu.shell.surface
      border.width: 2

      Text {
        id: searchIconItem
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        text: menu.searchIcon
        color: menu.shell.accent
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
        anchors.margins: 4
        leftPadding: 8
        rightPadding: 10
        verticalAlignment: TextInput.AlignVCenter
        focus: menu.focusWhenVisible
        text: menu.query
        color: menu.shell.fg
        selectionColor: menu.shell.accent
        selectedTextColor: menu.shell.bg
        font.family: "monospace"
        font.pixelSize: 15
        font.weight: Font.Bold

        Rectangle {
          anchors.fill: parent
          z: -1
          color: menu.shell.bg
        }

        onTextChanged: menu.queryEdited(text)

        Keys.onEscapePressed: menu.back()
        Keys.onDownPressed: {
          if (!menu.confirmVisible)
            list.currentIndex = Math.min(list.currentIndex + 1, menu.items.length - 1)
        }
        Keys.onUpPressed: {
          if (!menu.confirmVisible)
            list.currentIndex = Math.max(list.currentIndex - 1, 0)
        }
        Keys.onLeftPressed: {
          if (menu.confirmVisible)
            menu.confirmSelectionEdited("cancel")
        }
        Keys.onRightPressed: {
          if (menu.confirmVisible)
            menu.confirmSelectionEdited("confirm")
        }
        Keys.onPressed: event => {
          if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_C) {
            input.text = ""
            menu.clearRequested()
            event.accepted = true
          }
        }
        Keys.onReturnPressed: {
          if (menu.confirmVisible) {
            if (menu.confirmSelection === "confirm") menu.confirmAccepted()
            else menu.confirmCancelled()
          } else if (menu.items.length > 0 && list.currentIndex >= 0) {
            menu.accepted(menu.items[list.currentIndex])
          }
        }
      }
    }

    Rectangle {
      width: parent.width
      height: parent.height - 42 - parent.spacing
      radius: 5
      color: "transparent"
      border.color: menu.shell.surface
      border.width: 2

      ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 6
        clip: true
        model: menu.items
        currentIndex: 0

        delegate: Rectangle {
          required property var modelData
          required property int index

          width: ListView.view.width
          height: 36
          color: ListView.isCurrentItem ? menu.shell.hover : "transparent"

          Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            spacing: 12

            Item {
              width: 20
              height: 20
              anchors.verticalCenter: parent.verticalCenter

              Text {
                anchors.centerIn: parent
                visible: !menu.itemIconPath(modelData)
                text: menu.itemIcon(modelData)
                color: menu.shell.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                font.weight: Font.Bold
                font.italic: menu.italicPredicate(modelData)
                horizontalAlignment: Text.AlignHCenter
              }

              Image {
                anchors.fill: parent
                visible: !!menu.itemIconPath(modelData)
                source: menu.itemIconPath(modelData)
                sourceSize: Qt.size(20, 20)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
              }
            }

            Text {
              width: parent.width - 32
              text: menu.highlightedText(menu.itemText(modelData))
              textFormat: Text.RichText
              color: menu.shell.fg
              font.family: "monospace"
              font.pixelSize: 15
              font.weight: Font.Bold
              font.italic: menu.italicPredicate(modelData)
              anchors.verticalCenter: parent.verticalCenter
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
    }
  }

  Rectangle {
    anchors.fill: parent
    visible: menu.confirmVisible
    color: menu.shell.bg
    opacity: 0.96

    Column {
      anchors.centerIn: parent
      spacing: 18

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Are you sure?"
        color: menu.shell.fg
        font.family: "monospace"
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
