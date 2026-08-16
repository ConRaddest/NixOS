import QtQuick
import qs
import qs.services

Item {
  id: root

  property color iconColor: Colors.foreground
  property int iconSize: 16

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  Row {
    id: content

    anchors.centerIn: parent
    spacing: 4

    Text {
      text: BatteryService.batteryIcon
      color: root.iconColor
      font.family: "monospace"
      font.pixelSize: root.iconSize
    }
  }
}
