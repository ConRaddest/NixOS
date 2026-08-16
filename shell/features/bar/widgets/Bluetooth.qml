import QtQuick
import qs

Item {
  id: root

  property color iconColor: Colors.foreground
  property int iconSize: 16

  implicitWidth: icon.implicitWidth
  implicitHeight: icon.implicitHeight

  Text {
    id: icon

    anchors.centerIn: parent
    text: "󰂯"
    color: root.iconColor
    font.family: "monospace"
    font.pixelSize: root.iconSize
  }
}
