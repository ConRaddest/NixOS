import QtQuick
import Quickshell

// ─── Launcher window ─────────────────────────────────────────────────────────
// Floating keyboard-driven menu. All runtime state (query, selection, confirm)
// lives on the shell; this file only defines the window and its controls.
FloatingWindow {
  id: launcher

  required property var shell

  // ─── Inline component: ConfirmButton ──────────────────────────────────────
  // A bordered button used in the confirmation dialog.
  component ConfirmButton: Rectangle {
    id: button

    required property var shell
    property string text: ""
    property bool selected: false
    signal clicked()

    width: 110
    height: 32
    color: button.selected || mouse.containsMouse ? button.shell.selection : "transparent"
    border.color: button.selected || mouse.containsMouse ? button.shell.accent : button.shell.surfaceLight
    border.width: 2

    Text {
      anchors.centerIn: parent
      text: button.text
      color: button.shell.fg
      font.family: "monospace"
      font.pixelSize: 14
      font.weight: Font.Bold
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: button.clicked()
    }
  }

  // ─── Inline component: ConfirmOverlay ─────────────────────────────────────
  // Full-window modal for destructive actions. Left/right to choose, enter to confirm.
  component ConfirmOverlay: Rectangle {
    id: overlay

    required property var shell

    visible: overlay.shell.confirmItem !== null
    color: overlay.shell.bg
    opacity: 0.96

    Column {
      visible: overlay.shell.confirmItem !== null
      anchors.centerIn: parent
      spacing: 18

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: overlay.shell.confirmItem ? "Are you sure?" : ""
        color: overlay.shell.fg
        font.family: "monospace"
        font.pixelSize: 16
        font.weight: Font.Bold
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        ConfirmButton {
          shell: overlay.shell
          text: "Cancel"
          selected: overlay.shell.confirmSelection === "cancel"
          onClicked: overlay.shell.cancelConfirm()
        }

        ConfirmButton {
          shell: overlay.shell
          text: overlay.shell.confirmItem ? overlay.shell.confirmItem.name : "Confirm"
          selected: overlay.shell.confirmSelection === "confirm"
          onClicked: overlay.shell.runConfirm()
        }
      }
    }
  }
  property alias menuInputItem: menuInput
  property alias menuListItem: menuList

  screen: shell.launcherScreen
  visible: shell.menuOpen
  title: "shell-launcher"
  implicitWidth: 600
  implicitHeight: 460
  color: shell.bg

  // ─── Menu item data ──────────────────────────────────────────────────────
  // Exposed as launcher.menuItems so the shell root can drive filtering.
  // Set dynamicApps: true to populate Apps from all installed desktop entries
  // instead of the curated list below.
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
    { name: "Firefox",    icon: "󰈹", command: "firefox" },
    { name: "Nautilus",      icon: "󰉋", command: "nautilus" },
    { name: "LocalSend",  icon: "󰒍", command: "localsend_app" },
    { name: "Terminal",   icon: "󰆍", command: "kitty" },
    { name: "Code",       icon: "󰨞", command: "code" },
  ]

  readonly property var menuItems: [
    { name: "Apps", icon: "󰀻", items: dynamicApps ? dynamicAppItems : curatedAppItems },

    { name: "System", icon: "󰒓", items: [
      { name: "Wallpaper",  icon: "󰸉", command: "qs ipc call wallpaper open" },
      { name: "Clipboard",  icon: "󰅎", command: "qs ipc call clipboard open" },
      { name: "Wi-Fi",      icon: "󰖩", terminal: { klass: "wifi-manager",        title: "wifi-manager",        cmd: "impala" } },
      { name: "Bluetooth",  icon: "󰂯", terminal: { klass: "bluetooth-manager",   title: "bluetooth-manager",   cmd: "bluetui" } },
      { name: "Audio",      icon: "󰕾", terminal: { klass: "audio-manager",       title: "audio-manager",       cmd: "wiremix" } },
      { name: "Status",     icon: "", terminal: { klass: "performance-monitor", title: "performance-monitor", cmd: "btop" } },
    ] },

    { name: "NixOS", icon: "󱄅", items: [
      { name: "Build",      icon: "󰔷", terminal: { klass: "nixos-build",   title: "nixos-build",   cmd: "nos-build",   pause: true } },
      { name: "Update",     icon: "", terminal: { klass: "nixos-update",  title: "nixos-update",  cmd: "nos-update",  pause: true } },
      { name: "Sync",       icon: "󰑐", terminal: { klass: "nixos-refresh", title: "nixos-refresh", cmd: "nos-refresh", pause: true } },
      { name: "Check",      icon: "", terminal: { klass: "nixos-check",   title: "nixos-check",   cmd: "nos-check",   pause: true } },
    ] },

    { name: "Power", icon: "󰐥", items: [
      { name: "Lock",     icon: "󰌾", command: "hyprlock" },
      { name: "Logout",   icon: "󰍃", command: "uwsm stop",          confirm: true },
      { name: "Restart",  icon: "󰜉", command: "systemctl reboot",   confirm: true },
      { name: "Shutdown", icon: "󰐥", command: "systemctl poweroff", confirm: true },
    ] },

    { name: "Speed", icon: "󰓅", items: [
      { name: "High",   icon: "󱐋", command: "powerprofilesctl set performance" },
      { name: "Normal", icon: "󰾅", command: "powerprofilesctl set balanced" },
      { name: "Low",    icon: "󰌪", command: "powerprofilesctl set power-saver" },
    ] },
  ]

  // ─── UI ──────────────────────────────────────────────────────────────────
  Rectangle {
    anchors.fill: parent
    color: launcher.shell.bg

    Column {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10

      // ─── Search input ──────────────────────────────────────────────────
      Rectangle {
        width: parent.width
        height: 42
        radius: 5
        color: "transparent"
        border.color: launcher.shell.surfaceLight
        border.width: 2

        // Search icon glyph
        Text {
          id: searchIcon
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          width: 20
          text: "󰍉"
          color: launcher.shell.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 16
          font.weight: Font.Bold
          horizontalAlignment: Text.AlignHCenter
        }

        // Text field — Ctrl+C clears, arrows navigate, Escape goes back
        TextInput {
          id: menuInput
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.left: searchIcon.right
          anchors.right: parent.right
          anchors.margins: 4
          leftPadding: 8
          rightPadding: 10
          verticalAlignment: TextInput.AlignVCenter
          focus: launcher.shell.menuOpen
          text: launcher.shell.menuQuery
          color: launcher.shell.fg
          selectionColor: launcher.shell.accent
          selectedTextColor: launcher.shell.bg
          font.family: "monospace"
          font.pixelSize: 15
          font.weight: Font.Bold

          Rectangle {
            anchors.fill: parent
            z: -1
            color: launcher.shell.bg
          }

          onTextChanged: launcher.shell.menuQuery = text
          Keys.onEscapePressed: launcher.shell.menuBack()
          Keys.onDownPressed: {
            if (!launcher.shell.confirmItem)
              menuList.currentIndex = Math.min(menuList.currentIndex + 1, launcher.shell.filteredMenuItems.length - 1)
          }
          Keys.onUpPressed: {
            if (!launcher.shell.confirmItem)
              menuList.currentIndex = Math.max(menuList.currentIndex - 1, 0)
          }
          Keys.onLeftPressed: {
            if (launcher.shell.confirmItem)
              launcher.shell.confirmSelection = "cancel"
          }
          Keys.onRightPressed: {
            if (launcher.shell.confirmItem)
              launcher.shell.confirmSelection = "confirm"
          }
          Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_C) {
              menuInput.text = ""
              launcher.shell.menuQuery = ""
              event.accepted = true
            }
          }
          Keys.onReturnPressed: {
            if (launcher.shell.confirmItem)
              launcher.shell.runConfirmSelection()
            else if (launcher.shell.filteredMenuItems.length > 0 && menuList.currentIndex >= 0)
              launcher.shell.enterMenuItem(launcher.shell.filteredMenuItems[menuList.currentIndex])
          }
        }
      }

      // ─── Item list ────────────────────────────────────────────────────
      Rectangle {
        width: parent.width
        height: parent.height - 42 - parent.spacing
        radius: 5
        color: "transparent"
        border.color: launcher.shell.surfaceLight
        border.width: 2

        ListView {
          id: menuList
          anchors.fill: parent
          anchors.margins: 6
          clip: true
          model: launcher.shell.filteredMenuItems
          currentIndex: 0

          delegate: Rectangle {
            required property var modelData
            required property int index

            width: ListView.view.width
            height: 36
            color: ListView.isCurrentItem ? launcher.shell.hover : "transparent"

            Row {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              spacing: 12

              Item {
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                // Nerd-font glyph for non-app items
                Text {
                  anchors.centerIn: parent
                  visible: !modelData.iconPath
                  text: modelData.icon || ""
                  color: launcher.shell.accent
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 15
                  font.weight: Font.Bold
                  font.italic: launcher.shell.isCurrentPerformanceItem(modelData)
                  horizontalAlignment: Text.AlignHCenter
                }

                // Full-color app icon from the desktop entry
                Image {
                  anchors.fill: parent
                  visible: !!modelData.iconPath
                  source: modelData.iconPath || ""
                  sourceSize: Qt.size(20, 20)
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                }
              }

              Text {
                text: launcher.shell.highlightedText(modelData.name)
                textFormat: Text.RichText
                color: launcher.shell.fg
                font.family: "monospace"
                font.pixelSize: 15
                font.weight: Font.Bold
                font.italic: launcher.shell.isCurrentPerformanceItem(modelData)
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: menuList.currentIndex = index
              onClicked: launcher.shell.enterMenuItem(modelData)
            }
          }
        }
      }
    }

    // ─── Confirm overlay ───────────────────────────────────────────────────
    // Shown on top of the list when a destructive action needs confirmation.
    ConfirmOverlay {
      anchors.fill: parent
      shell: launcher.shell
    }
  }
}
