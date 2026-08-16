import QtQuick
import QtQuick.Layouts
import qs
import qs.services

Rectangle {
  id: root

  property string icon: BatteryService.batteryIcon
  property string heading: "Battery"
  property string subheading: "Threshold"
  property Component actionComponent: null

  // Let the parent layout manage width and placement
  implicitHeight: 60
  Layout.fillWidth: true
  color: Colors.background

  RowLayout {
    anchors.fill: parent
    spacing: 15

    Text {
      text: root.icon
      color: Colors.foreground
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 36
      Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
      spacing: 2
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter

      Text {
        id: heading
        text: root.heading
        color: Colors.foreground
        font.family: "monospace"
        font.bold: true
        font.pixelSize: 20
      }

      Text {
        id: subheading
        text: root.subheading
        font.capitalization: Font.AllUppercase
        color: Colors.dark_foreground
        font.family: "monospace"
        font.pixelSize: 14
      }
    }

    Item {
      Layout.fillWidth: true
    }

    // Dynamic Loader for custom action components
    Loader {
      sourceComponent: root.actionComponent
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
