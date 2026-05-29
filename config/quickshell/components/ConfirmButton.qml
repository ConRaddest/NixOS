import QtQuick

Rectangle {
  id: button

  required property var shell
  property string text: ""
  property bool selected: false
  signal clicked()

  width: 110
  height: 32
  color: selected || mouse.containsMouse ? shell.selection : "transparent"
  border.color: selected || mouse.containsMouse ? shell.accent : shell.surfaceLight
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
