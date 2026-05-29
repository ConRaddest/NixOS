{ config, pkgs, colors, font, ... }:

let
  repo = "${config.home.homeDirectory}/OS/config";
in
{
  home.packages = [ pkgs.quickshell ];

  # shell.qml is generated so it can pull tokens from the shared `colors`/`font`
  # set in home.nix. The components/ directory stays as an out-of-store symlink
  # so QML edits don't need a rebuild.
  xdg.configFile."quickshell/shell.qml".text = ''
    //@ pragma ShellId shell

    import QtQuick
    import Quickshell
    import Quickshell.Io
    import Quickshell.Hyprland
    import "components"

    ShellRoot {
      id: root

      readonly property string bg:       "${colors.bg}"
      readonly property string bgAlt:    "${colors.bgAlt}"
      readonly property string fg:       "${colors.fg}"
      readonly property string fgDim:    "${colors.comment}"
      readonly property string accent:   "${colors.blue}"

      readonly property string monoFont: "${font.mono}"

      readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id || 1
      property var occupiedWorkspaceIds: []

      property string cpuText:       "--"
      property string ramText:       "--"
      property string wifiText:      "󰖪"
      property string bluetoothText: "󰂲"
      property string batteryText:   "󰚥 AC"

      function workspaceIds() {
        const ids = occupiedWorkspaceIds.slice()
        if (!ids.includes(activeWorkspace))
          ids.push(activeWorkspace)
        return ids.sort((a, b) => a - b)
      }

      function runDetached(command) {
        launchProcess.command = ["bash", "-lc", "setsid bash -lc " + shellQuote(command) + " >/dev/null 2>&1 &"]
        launchProcess.running = true
      }

      function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\'''") + "'"
      }

      Process { id: launchProcess }

      Process {
        id: workspaceProcess
        stdout: StdioCollector {
          onStreamFinished: {
            const text = this.text.trim()
            root.occupiedWorkspaceIds = text === "" ? [] : text.split(",").map(id => Number(id))
          }
        }
      }

      Process {
        id: statusProcess
        stdout: StdioCollector {
          onStreamFinished: {
            const parts = this.text.trim().split("|")
            if (parts.length >= 5) {
              root.cpuText       = parts[0]
              root.ramText       = parts[1]
              root.wifiText      = parts[2]
              root.bluetoothText = parts[3]
              root.batteryText   = parts[4]
            }
          }
        }
      }

      Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
          workspaceProcess.running = false
          workspaceProcess.command = ["bash", "-c", "hyprctl clients -j | jq -r '[.[].workspace.id | select(. > 0)] | unique | join(\",\")'"]
          workspaceProcess.running = true

          statusProcess.running = false
          statusProcess.command = ["bash", "-c", "$HOME/.config/quickshell/scripts/status.sh"]
          statusProcess.running = true
        }
      }

      Variants {
        model: Quickshell.screens

        StatusBar {
          required property var modelData
          screen: modelData
          shell: root
        }
      }
    }
  '';

  xdg.configFile."quickshell/components" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repo}/quickshell/components";
    recursive = true;
  };

  xdg.configFile."quickshell/scripts" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repo}/quickshell/scripts";
    recursive = true;
  };
}
