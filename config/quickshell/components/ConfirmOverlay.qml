import QtQuick

// Modal confirmation shown for destructive power/session actions.
Rectangle {
  id: overlay

  required property var shell

  visible: shell.confirmItem !== null
  color: shell.bg
  opacity: 0.96

  Column {
    visible: overlay.shell.confirmItem !== null
    anchors.centerIn: parent
    spacing: 18

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: overlay.shell.confirmItem ? "Are you sure?" : ""
      color: overlay.shell.fg
      font.family: "monospace"
      font.pixelSize: 16
      font.weight: Font.Bold
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12

      ConfirmButton {
        shell: overlay.shell
        text: "Cancel"
        selected: overlay.shell.confirmSelection === "cancel"
        onClicked: overlay.shell.cancelConfirm()
      }

      ConfirmButton {
        shell: overlay.shell
        text: overlay.shell.confirmItem ? overlay.shell.confirmItem.name : "Confirm"
        selected: overlay.shell.confirmSelection === "confirm"
        onClicked: overlay.shell.runConfirm()
      }
    }
  }
}
