import QtQuick
import Quickshell
import Quickshell.Hyprland

PanelWindow {
  id: bar

  required property var shell

  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: 30
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: bar.shell.bg

    // Left: active workspace + workspaces with windows.
    Row {
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Repeater {
        model: bar.shell.workspaceIds()

        Rectangle {
          required property int modelData

          readonly property bool active: bar.shell.activeWorkspace === modelData

          width: 22
          height: 22
          radius: 6
          color: active ? bar.shell.bgAlt : "transparent"
          border.color: active ? bar.shell.accent : "transparent"
          border.width: active ? 1 : 0

          Text {
            anchors.centerIn: parent
            text: parent.modelData
            color: parent.active ? bar.shell.fg : bar.shell.fgDim
            font.family: bar.shell.monoFont
            font.pixelSize: 13
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.shell.runDetached("hyprctl dispatch workspace " + parent.modelData)
          }
        }
      }
    }

    // Middle: reserved.
    Row {
      anchors.centerIn: parent
      spacing: 6
    }

    // Right: system status indicators.
    Row {
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      StatusPill { shell: bar.shell; text: bar.shell.wifiText }
      StatusPill { shell: bar.shell; text: bar.shell.bluetoothText }
      StatusPill { shell: bar.shell; text: "  " + bar.shell.cpuText }
      StatusPill { shell: bar.shell; text: "  " + bar.shell.ramText }
      StatusPill { shell: bar.shell; text: bar.shell.batteryText }
    }
  }
}
