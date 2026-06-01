import QtQuick
import Quickshell
import Quickshell.Io

// ─── Theme picker window ──────────────────────────────────────────────────────
FloatingWindow {
  id: themePicker

  required property var shell

  property string query: ""
  property var themeItems: []
  property string currentTheme: ""

  visible: shell.themeOpen
  title: "theme-picker"
  implicitWidth: 760
  implicitHeight: 460
  color: shell.bg

  // ─── Read current theme symlink target ───────────────────────────────────
  Process {
    id: currentProcess
    stdout: StdioCollector {
      onStreamFinished: {
        themePicker.currentTheme = this.text.trim()
        fetchProcess.running = false
        fetchProcess.command = ["bash", "-c",
          "find " + shell.shellQuote(shell.themeDir) +
          " -mindepth 1 -maxdepth 1 -type d" +
          " | sed 's|.*/||' | sort"
        ]
        fetchProcess.running = true
      }
    }
  }

  // ─── List available themes ────────────────────────────────────────────────
  Process {
    id: fetchProcess
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.trim().split("\n").filter(l => l.trim() !== "")
        themePicker.themeItems = lines.map(id => ({
          id: id,
          name: themePicker.toDisplayName(id),
          icon: id === themePicker.currentTheme ? "󰸞" : "󰏘",
        }))
      }
    }
  }

  function toDisplayName(id) {
    return id.split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
  }

  function applyTheme(item) {
    if (!item) return
    shell.launchTerminal("theme-apply", "theme-apply", "nos-theme " + item.id, true)
    shell.themeOpen = false
  }

  function refresh() {
    currentProcess.running = false
    currentProcess.command = ["bash", "-c",
      "readlink " + shell.shellQuote(shell.themeDir + "/current.nix") +
      " | sed 's|.*/||; s|/theme\\.nix$||'"
    ]
    currentProcess.running = true
  }

  ListPreviewPicker {
    id: picker
    anchors.fill: parent
    shell: themePicker.shell
    searchIcon: "󰍉"
    query: themePicker.query
    items: themePicker.themeItems
    itemText: function(item) { return item.name }
    itemIcon: function(item) { return item.icon }
    itemMatches: function(item, q) { return item.name.toLowerCase().includes(q) }
    imageSource: function(item) {
      return item ? "file://" + shell.themeDir + "/" + item.id + "/preview.png" : ""
    }
    highlightedText: function(text) { return themePicker.shell.highlightedText(text) }

    onQueryEdited: query => themePicker.query = query
    onAccepted: item => themePicker.applyTheme(item)
    onBack: themePicker.shell.themeOpen = false
  }

  onVisibleChanged: {
    if (visible) {
      query = ""
      refresh()
      picker.inputItem.forceActiveFocus()
    }
  }

  onClosed: themePicker.shell.themeOpen = false
}
