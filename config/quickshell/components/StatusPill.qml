import QtQuick

Rectangle {
  id: pill

  required property var shell
  property string text: ""
  property bool clickable: false
  signal clicked()

  width: label.implicitWidth + 14
  height: 24
  radius: 6
  color: clickable && mouse.containsMouse ? shell.bgAlt : "transparent"

  Text {
    id: label
    anchors.centerIn: parent
    text: pill.text
    color: pill.shell.fg
    font.family: pill.shell.monoFont
    font.pixelSize: 13
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: pill.clickable
    hoverEnabled: pill.clickable
    cursorShape: pill.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: pill.clicked()
  }
}
