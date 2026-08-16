import QtQuick
import QtQuick.Layouts
import Quickshell
import "widgets/datetime"

Variants {
  model: Quickshell.screens

  PanelWindow {
    required property var modelData

    screen: modelData
    color: "transparent"
    implicitHeight: 30

    anchors {
      top: true
      left: true
      right: true
    }

    Rectangle {
      anchors.fill: parent
      color: "#1a1b26"

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Item {
          Layout.fillWidth: true
        }

        Datetime {}
      }
    }
  }
}
