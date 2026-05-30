import QtQuick
import Quickshell
import Quickshell.Hyprland

// ─── Bar window ──────────────────────────────────────────────────────────────
// Anchored full-width panel at the top of each monitor.
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

  // ─── Inline component: StatusPill ────────────────────────────────────────
  // Small clickable status indicator used in the right section of the bar.
  component StatusPill: Rectangle {
    id: pill

    required property var shell
    property string text: ""
    property bool clickable: false
    signal clicked()

    width: label.implicitWidth + 14
    height: 24
    radius: 6
    color: pill.clickable && mouse.containsMouse ? pill.shell.bgAlt : "transparent"

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

  // ─── Monitor binding ─────────────────────────────────────────────────────
  // Find the Hyprland monitor whose name matches this bar's screen.
  readonly property HyprlandMonitor hyprMonitor: {
    for (const m of Hyprland.monitors.values) {
      if (m.name === bar.screen.name) return m
    }
    return null
  }

  // Collect workspace IDs visible on this monitor (occupied + active).
  readonly property var monitorWorkspaceIds: {
    const ids = []
    for (const ws of Hyprland.workspaces.values) {
      if (ws.monitor?.name === bar.screen.name && !ids.includes(ws.id))
        ids.push(ws.id)
    }
    const active = bar.hyprMonitor?.activeWorkspace?.id
    if (active && !ids.includes(active)) ids.push(active)
    return ids.sort((a, b) => a - b)
  }

  readonly property int monitorActiveWorkspace: bar.hyprMonitor?.activeWorkspace?.id || 0

  // ─── Background ──────────────────────────────────────────────────────────
  Rectangle {
    anchors.fill: parent
    color: bar.shell.bg

    // ─── Left: workspace indicators ───────────────────────────────────────
    Row {
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Repeater {
        model: bar.monitorWorkspaceIds

        Rectangle {
          required property int modelData

          readonly property bool active: bar.monitorActiveWorkspace === modelData

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
            onClicked: Hyprland.dispatch("workspace " + parent.modelData)
          }
        }
      }
    }

    // ─── Center: clock ────────────────────────────────────────────────────
    Text {
      anchors.centerIn: parent
      text: bar.shell.timeText
      color: bar.shell.fg
      font.family: bar.shell.monoFont
      font.pixelSize: 13
    }

    // ─── Right: system status pills ───────────────────────────────────────
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
      StatusPill {
        shell: bar.shell
        text: bar.shell.batteryText
        clickable: true
        onClicked: bar.shell.runDetached("qs ipc call launcher openSubmenu Speed")
      }
    }
  }
}
