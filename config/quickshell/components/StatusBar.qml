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
          border.color: active ? bar.shell.fg : "transparent"
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
            // hyprland-lua wraps dispatch input as `hl.dispatch(<text>)` and
            // expects a dispatcher object — same form keybinds use.
            onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.modelData + " })")
          }
        }
      }
    }

    // Middle: clock.
    Text {
      anchors.centerIn: parent
      text: bar.shell.timeText
      color: bar.shell.fg
      font.family: bar.shell.monoFont
      font.pixelSize: 13
    }

    // Right: system status indicators.
    Row {
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      StatusPill {
        shell: bar.shell
        text: bar.shell.wifiText
        clickable: true
        onClicked: bar.shell.launchTerminal("wifi-manager", "wifi-manager", "impala")
      }
      StatusPill {
        shell: bar.shell
        text: bar.shell.bluetoothText
        clickable: true
        onClicked: bar.shell.launchTerminal("bluetooth-manager", "bluetooth-manager", "bluetui")
      }
      StatusPill {
        shell: bar.shell
        text: bar.shell.cpuText
        clickable: true
        onClicked: bar.shell.launchTerminal("performance-monitor", "performance-monitor", "btop")
      }
      StatusPill {
        shell: bar.shell
        text: bar.shell.ramText
        clickable: true
        onClicked: bar.shell.launchTerminal("performance-monitor", "performance-monitor", "btop")
      }
      StatusPill { shell: bar.shell; text: bar.shell.batteryText }
    }
  }
}
