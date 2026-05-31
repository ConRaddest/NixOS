import QtQuick
import Quickshell
import Quickshell.Io

// ─── Clipboard history window ─────────────────────────────────────────────────
FloatingWindow {
  id: clipboardWindow

  required property var shell

  property string clipQuery: ""
  property var clipItems: []
  property var selectedItem: null
  property string previewText: ""
  property string previewImage: ""

  screen: shell.launcherScreen
  visible: shell.clipboardOpen
  title: "shell-clipboard"
  implicitWidth: 760
  implicitHeight: 460
  color: shell.bg

  onVisibleChanged: {
    if (visible) {
      clipQuery = ""
      previewText = ""
      previewImage = ""
      fetchProcess.running = false
      fetchProcess.command = ["bash", "-c", "cliphist list 2>/dev/null || true"]
      fetchProcess.running = true
      picker.inputItem.forceActiveFocus()
    } else {
      clipQuery = ""
    }
  }

  Process {
    id: fetchProcess
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.trim().split("\n").filter(l => l.trim() !== "")
        clipboardWindow.clipItems = lines.map(line => {
          const tabIdx = line.indexOf("\t")
          const id = tabIdx >= 0 ? line.slice(0, tabIdx) : line
          const content = tabIdx >= 0 ? line.slice(tabIdx + 1) : line
          const image = /^\[\[ binary data .*\b(png|jpe?g|webp)\b/i.test(content)
          return {
            id: id,
            raw: line,
            display: image ? "Image" : content.replace(/\s+/g, " ").trim(),
            details: content.replace(/\s+/g, " ").trim(),
            isImage: image,
            icon: image ? "󰋩" : "󰆒",
          }
        })
      }
    }
  }

  Process { id: copyProcess }

  Process {
    id: previewProcess
    stdout: StdioCollector {
      onStreamFinished: {
        if (clipboardWindow.selectedItem && clipboardWindow.selectedItem.isImage) {
          clipboardWindow.previewImage = "file://" + this.text.trim() + "?t=" + Date.now()
        } else {
          clipboardWindow.previewText = this.text
        }
      }
    }
  }

  function copyItem(item) {
    if (!item) return
    const type = item.isImage ? " | wl-copy --type image/png" : " | wl-copy"
    copyProcess.command = ["bash", "-c", "printf '%s\n' " + shell.shellQuote(item.raw) + " | cliphist decode" + type]
    copyProcess.running = true
    shell.closeClipboard()
  }

  function previewItem(item) {
    selectedItem = item
    previewText = ""
    previewImage = ""
    previewProcess.running = false

    if (!item) return

    if (item.isImage) {
      const path = "/tmp/quickshell-clipboard-preview-" + item.id + ".png"
      previewProcess.command = ["bash", "-c", "printf '%s\n' " + shell.shellQuote(item.raw) + " | cliphist decode > " + shell.shellQuote(path) + " && printf '%s' " + shell.shellQuote(path)]
    } else {
      previewProcess.command = ["bash", "-c", "printf '%s\n' " + shell.shellQuote(item.raw) + " | cliphist decode"]
    }
    previewProcess.running = true
  }

  ListPreviewPicker {
    id: picker
    anchors.fill: parent
    shell: clipboardWindow.shell
    searchIcon: "󰅎"
    query: clipboardWindow.clipQuery
    items: clipboardWindow.clipItems
    itemText: function(item) { return item.display }
    itemIcon: function(item) { return item.icon }
    itemMatches: function(item, q) { return item.display.toLowerCase().includes(q) || item.details.toLowerCase().includes(q) }
    isImage: function(item) { return item && item.isImage }
    imageSource: function(item) { return clipboardWindow.previewImage }
    previewText: function(item) { return clipboardWindow.previewText }

    onQueryEdited: query => clipboardWindow.clipQuery = query
    onAccepted: item => clipboardWindow.copyItem(item)
    onSelectedItemChanged: item => clipboardWindow.previewItem(item)
    onBack: clipboardWindow.shell.closeClipboard()
  }
}
