import QtQuick
import Quickshell
import Quickshell.Io

// ─── Wallpaper picker window ─────────────────────────────────────────────────
FloatingWindow {
  id: wallpaper

  required property var shell

  property string query: ""
  property var wallpaperItems: []

  visible: shell.wallpaperOpen
  title: "wallpaper-picker"
  implicitWidth: 760
  implicitHeight: 460
  color: shell.bg

  Process { id: wallpaperProcess }

  Process {
    id: fetchProcess
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.trim().split("\n").filter(l => l.trim() !== "")
        wallpaper.wallpaperItems = lines.map(path => ({
          path: path,
          name: wallpaper.fileName(path),
          icon: "󰉏",
        }))
      }
    }
  }

  function fileName(path) {
    const parts = String(path).split("/")
    return parts[parts.length - 1]
  }

  function displayPath(path) {
    const home = String(shell.homeDir).replace(/^file:\/\//, "")
    return String(path).replace(home, "~")
  }

  function applyWallpaper(item) {
    if (!item || !item.path) return
    wallpaperProcess.command = [shell.assetDir + "/shell/scripts/wallpaper.sh", item.path]
    wallpaperProcess.running = true
    shell.wallpaperOpen = false
  }

  function refresh() {
    fetchProcess.running = false
    fetchProcess.command = ["bash", "-c", "find " + shell.shellQuote(shell.wallpaperDir) + " -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort"]
    fetchProcess.running = true
  }

  ListPreviewPicker {
    id: picker
    anchors.fill: parent
    shell: wallpaper.shell
    searchIcon: "󰍉"
    query: wallpaper.query
    items: wallpaper.wallpaperItems
    itemText: function(item) { return item.name }
    itemIcon: function(item) { return item.icon }
    itemMatches: function(item, q) { return item.name.toLowerCase().includes(q) }
    imageSource: function(item) { return item ? "file://" + item.path : "" }

    onQueryEdited: query => wallpaper.query = query
    onAccepted: item => wallpaper.applyWallpaper(item)
    onBack: wallpaper.shell.wallpaperOpen = false
  }

  onVisibleChanged: {
    if (visible) {
      query = ""
      refresh()
      picker.inputItem.forceActiveFocus()
    }
  }

  onClosed: wallpaper.shell.wallpaperOpen = false
}
