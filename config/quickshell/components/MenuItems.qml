import QtQuick
import Quickshell

QtObject {
  // Switch to true to populate Apps from all installed desktop entries.
  // When false, the curated list below is used with nerd-font glyphs.
  readonly property bool dynamicApps: false

  readonly property var dynamicAppItems: {
    DesktopEntries.applicationsChanged
    return DesktopEntries.applications.values
      .filter(e => !e.noDisplay)
      .map(e => ({
        name: e.name,
        iconPath: e.icon ? Quickshell.iconPath(e.icon) : "",
        desktop: e.id,
      }))
      .sort((a, b) => a.name.localeCompare(b.name))
  }

  readonly property var curatedAppItems: [
    { name: "Firefox",   icon: "󰈹", desktop: "firefox" },
    { name: "Nautilus",  icon: "󰉋", desktop: "org.gnome.Nautilus" },
    { name: "LocalSend", icon: "󰒍", desktop: "LocalSend" },
    { name: "Terminal",  icon: "󰆍", desktop: "kitty" },
    { name: "VS Code",   icon: "󰨞", desktop: "code" },
  ]

  readonly property var items: [
    { name: "Apps", icon: "󰀻", items: dynamicApps ? dynamicAppItems : curatedAppItems },

    { name: "System", icon: "󰒓", items: [
      { name: "Refresh",    icon: "󰑐", terminal: { klass: "nixos-refresh", title: "nixos-refresh", cmd: "home-manager switch --flake $HOME/OS#cdt",                      pause: true } },
      { name: "Build",      icon: "󰔷", terminal: { klass: "nixos-build",  title: "nixos-build",  cmd: "sudo nixos-rebuild switch --flake $HOME/OS#nixos",             pause: true } },
      { name: "Update",     icon: "󰚰", terminal: { klass: "nixos-update", title: "nixos-update", cmd: "nix flake update --flake $HOME/OS && sudo nixos-rebuild switch --flake $HOME/OS#nixos", pause: true } },
      { name: "Check",      icon: "󰁨", terminal: { klass: "nixos-check",  title: "nixos-check",  cmd: "sudo nixos-rebuild dry-run --flake $HOME/OS#nixos",              pause: true } },
      { name: "Wallpaper",  icon: "󰸉", command: "qs ipc call wallpaper open" },
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
