import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import "widgets/datetime"

Variants {
  model: Quickshell.screens

  PanelWindow {
    required property var modelData

    implicitHeight: 30

    anchors {
      top: true
      left: true
      right: true
    }

    Rectangle {
      anchors.fill: parent
      color: Colors.background

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Datetime {}

        Item {
          Layout.fillWidth: true
        }

        Datetime {}

        Item {
          Layout.fillWidth: true
        }

        Datetime {}
      }
    }
  }
}
