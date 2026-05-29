import QtQuick

QtObject {
  readonly property var items: [
    { name: "Apps", icon: "󰀻", items: [
      { name: "Firefox",   icon: "󰈹", command: "firefox" },
      { name: "Nautilus",  icon: "󰉋", command: "nautilus" },
      { name: "Yazi",      icon: "󰝰", terminal: { klass: "terminal-file-manager", title: "terminal-file-manager", cmd: "yazi" } },
      { name: "LocalSend", icon: "󰒍", command: "localsend_app" },
      { name: "Terminal",  icon: "󰆍", command: "kitty" },
      { name: "VS Code",   icon: "󰨞", command: "code" },
    ] },

    { name: "System", icon: "󰒓", items: [
      { name: "Refresh",    icon: "󰑐", terminal: { klass: "nixos-refresh", title: "nixos-refresh", cmd: "home-manager switch --flake $HOME/OS#cdt",                      pause: true } },
      { name: "Build",      icon: "󰔷", terminal: { klass: "nixos-build",  title: "nixos-build",  cmd: "sudo nixos-rebuild switch --flake $HOME/OS#nixos",             pause: true } },
      { name: "Update",     icon: "󰚰", terminal: { klass: "nixos-update", title: "nixos-update", cmd: "nix flake update --flake $HOME/OS && sudo nixos-rebuild switch --flake $HOME/OS#nixos", pause: true } },
      { name: "Check",      icon: "󰁨", terminal: { klass: "nixos-check",  title: "nixos-check",  cmd: "sudo nixos-rebuild dry-run --flake $HOME/OS#nixos",              pause: true } },
      { name: "Wi-Fi",      icon: "󰖩", terminal: { klass: "wifi-manager",        title: "wifi-manager",        cmd: "impala" } },
      { name: "Bluetooth",  icon: "󰂯", terminal: { klass: "bluetooth-manager",   title: "bluetooth-manager",   cmd: "bluetui" } },
      { name: "Audio",      icon: "󰕾", terminal: { klass: "audio-manager",       title: "audio-manager",       cmd: "wiremix" } },
      { name: "Status",     icon: "󰓅", terminal: { klass: "performance-monitor", title: "performance-monitor", cmd: "btop" } },
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
