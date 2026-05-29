import QtQuick

QtObject {
  readonly property var items: [
    { name: "Apps", icon: "󰀻", items: [
      { name: "Firefox",   icon: "󰈹", command: "firefox" },
      { name: "Nautilus",  icon: "󰉋", command: "nautilus" },
      { name: "Yazi",      icon: "󰝰", command: "kitty --class terminal-file-manager --title terminal-file-manager -e yazi" },
      { name: "LocalSend", icon: "󰒍", command: "localsend_app" },
      { name: "Terminal",  icon: "󰆍", command: "kitty" },
      { name: "VS Code",   icon: "󰨞", command: "code" },
    ] },

    { name: "System", icon: "󰒓", items: [
      { name: "Build",     icon: "󰔷", command: "kitty --class nixos-build --title nixos-build -e bash -lc 'NIXOS_REPO=$HOME/OS $HOME/.config/quickshell/scripts/nixos-action.sh build; echo; read -r -p \"Press Enter to close...\"'" },
      { name: "Update",    icon: "󰚰", command: "kitty --class nixos-update --title nixos-update -e bash -lc 'NIXOS_REPO=$HOME/OS $HOME/.config/quickshell/scripts/nixos-action.sh update; echo; read -r -p \"Press Enter to close...\"'" },
      { name: "Check",     icon: "󰁨", command: "kitty --class nixos-check --title nixos-check -e bash -lc 'NIXOS_REPO=$HOME/OS $HOME/.config/quickshell/scripts/nixos-action.sh check; echo; read -r -p \"Press Enter to close...\"'" },
      { name: "Wi-Fi",     icon: "󰖩", command: "kitty --class wifi-manager --title wifi-manager -e impala" },
      { name: "Bluetooth", icon: "󰂯", command: "kitty --class bluetooth-manager --title bluetooth-manager -e bluetui" },
      { name: "Audio",     icon: "󰕾", command: "kitty --class audio-manager --title audio-manager -e wiremix" },
      { name: "Status",    icon: "󰓅", command: "kitty --class performance-monitor --title performance-monitor -e btop" },
    ] },

    { name: "Power", icon: "󰐥", items: [
      { name: "Lock",     icon: "󰌾", command: "hyprlock" },
      { name: "Logout",   icon: "󰍃", command: "uwsm stop", confirm: true },
      { name: "Restart",  icon: "󰜉", command: "systemctl reboot", confirm: true },
      { name: "Shutdown", icon: "󰐥", command: "systemctl poweroff", confirm: true },
    ] },

    { name: "Speed", icon: "󰓅", items: [
      { name: "High",   icon: "󱐋", command: "powerprofilesctl set performance" },
      { name: "Normal", icon: "󰾅", command: "powerprofilesctl set balanced" },
      { name: "Low",    icon: "󰌪", command: "powerprofilesctl set power-saver" },
    ] },
  ]
}
