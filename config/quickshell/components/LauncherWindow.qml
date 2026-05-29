import QtQuick
import Quickshell

// Floating keyboard-driven launcher/menu. All state and behaviour lives on the
// ShellRoot; this file only defines the window and controls.
FloatingWindow {
  id: launcher

  required property var shell
  property alias menuInputItem: menuInput
  property alias menuListItem: menuList

  visible: shell.menuOpen
  title: "shell-launcher"
  implicitWidth: 600
  implicitHeight: 460
  color: shell.bg

  Rectangle {
    anchors.fill: parent
    color: launcher.shell.bg

    Column {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10

      Rectangle {
        width: parent.width
        height: 42
        radius: 5
        color: "transparent"
        border.color: launcher.shell.surfaceLight
        border.width: 2

        Text {
          id: searchIcon
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          width: 20
          text: "󰍉"
          color: launcher.shell.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 16
          font.weight: Font.Bold
          horizontalAlignment: Text.AlignHCenter
        }

        TextInput {
          id: menuInput
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.left: searchIcon.right
          anchors.right: parent.right
          anchors.margins: 4
          leftPadding: 8
          rightPadding: 10
          verticalAlignment: TextInput.AlignVCenter
          focus: launcher.shell.menuOpen
          text: launcher.shell.menuQuery
          color: launcher.shell.fg
          selectionColor: launcher.shell.accent
          selectedTextColor: launcher.shell.bg
          font.family: "monospace"
          font.pixelSize: 15
          font.weight: Font.Bold

          Rectangle {
            anchors.fill: parent
            z: -1
            color: launcher.shell.bg
          }

          onTextChanged: launcher.shell.menuQuery = text
          Keys.onEscapePressed: launcher.shell.menuBack()
          Keys.onDownPressed: {
            if (!launcher.shell.confirmItem)
              menuList.currentIndex = Math.min(menuList.currentIndex + 1, launcher.shell.filteredMenuItems.length - 1)
          }
          Keys.onUpPressed: {
            if (!launcher.shell.confirmItem)
              menuList.currentIndex = Math.max(menuList.currentIndex - 1, 0)
          }
          Keys.onLeftPressed: {
            if (launcher.shell.confirmItem)
              launcher.shell.confirmSelection = "cancel"
          }
          Keys.onRightPressed: {
            if (launcher.shell.confirmItem)
              launcher.shell.confirmSelection = "confirm"
          }
          Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_C) {
              menuInput.text = ""
              launcher.shell.menuQuery = ""
              event.accepted = true
            }
          }
          Keys.onReturnPressed: {
            if (launcher.shell.confirmItem)
              launcher.shell.runConfirmSelection()
            else if (launcher.shell.filteredMenuItems.length > 0 && menuList.currentIndex >= 0)
              launcher.shell.enterMenuItem(launcher.shell.filteredMenuItems[menuList.currentIndex])
          }
        }
      }

      Rectangle {
        width: parent.width
        height: parent.height - 42 - parent.spacing
        radius: 5
        color: "transparent"
        border.color: launcher.shell.surfaceLight
        border.width: 2

        ListView {
          id: menuList
          anchors.fill: parent
          anchors.margins: 6
          clip: true
          model: launcher.shell.filteredMenuItems
          currentIndex: 0

          delegate: Rectangle {
            required property var modelData
            required property int index

            width: ListView.view.width
            height: 36
            color: ListView.isCurrentItem ? launcher.shell.hover : "transparent"

            Row {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              spacing: 12

              Text {
                width: 20
                text: modelData.icon || ""
                color: launcher.shell.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                font.weight: Font.Bold
                font.italic: launcher.shell.isCurrentPerformanceItem(modelData)
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: launcher.shell.highlightedText(modelData.name)
                textFormat: Text.RichText
                color: launcher.shell.fg
                font.family: "monospace"
                font.pixelSize: 15
                font.weight: Font.Bold
                font.italic: launcher.shell.isCurrentPerformanceItem(modelData)
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: menuList.currentIndex = index
              onClicked: launcher.shell.enterMenuItem(modelData)
            }
          }
        }
      }
    }

    ConfirmOverlay {
      anchors.fill: parent
      shell: launcher.shell
    }
  }
}
