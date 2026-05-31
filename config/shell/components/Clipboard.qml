import QtQuick
import Quickshell
import Quickshell.Io

// ─── Clipboard history window ─────────────────────────────────────────────────
FloatingWindow {
  id: clipboardWindow

  required property var shell

  property string clipQuery: ""
  property var clipItems: []

  property alias clipInputItem: menu.inputItem
  property alias clipListItem:  menu.listItem

  readonly property var filteredItems: getFilteredItems()

  screen: shell.launcherScreen
  visible: shell.clipboardOpen
  title: "shell-clipboard"
  implicitWidth: 450
  implicitHeight: 400
  color: shell.bg

  onVisibleChanged: {
    if (visible) {
      clipQuery = ""
      if (menu.inputItem) menu.inputItem.forceActiveFocus()
      if (menu.listItem) menu.listItem.currentIndex = 0
      fetchProcess.running = false
      fetchProcess.command = ["bash", "-c", "cliphist list 2>/dev/null || true"]
      fetchProcess.running = true
    } else {
      clipQuery = ""
    }
  }

  onFilteredItemsChanged: {
    if (menu.listItem) menu.listItem.currentIndex = 0
  }

  Process {
    id: fetchProcess
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.trim().split("\n").filter(l => l.trim() !== "")
        clipboardWindow.clipItems = lines.map(line => {
          const tabIdx = line.indexOf("\t")
          const content = tabIdx >= 0 ? line.slice(tabIdx + 1) : line
          return { raw: line, display: content.replace(/\s+/g, " ").trim() }
        })
      }
    }
  }

  Process { id: copyProcess }

  function getFilteredItems() {
    const q = clipQuery.trim().toLowerCase()
    if (q === "") return clipItems
    return clipItems.filter(item => item.display.toLowerCase().includes(q))
  }

  function copyItem(item) {
    copyProcess.command = ["bash", "-c", "printf '%s\n' " + shellQuote(item.raw) + " | cliphist decode | wl-copy"]
    copyProcess.running = true
    shell.closeClipboard()
  }

  function highlightedClipText(text) {
    const value = String(text)
    const query = clipQuery.trim()
    if (query === "") return escapeHtml(value)
    const lowerValue = value.toLowerCase()
    const lowerQuery = query.toLowerCase()
    let result = ""
    let position = 0
    let match = lowerValue.indexOf(lowerQuery, position)
    while (match !== -1) {
      result += escapeHtml(value.slice(position, match))
      result += "<span style=\"color: " + shell.accent + "\">" + escapeHtml(value.slice(match, match + query.length)) + "</span>"
      position = match + query.length
      match = lowerValue.indexOf(lowerQuery, position)
    }
    return result + escapeHtml(value.slice(position))
  }

  function escapeHtml(text) {
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
  }

  function shellQuote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
  }

  SearchMenu {
    id: menu
    anchors.fill: parent
    shell: clipboardWindow.shell
    query: clipboardWindow.clipQuery
    items: clipboardWindow.filteredItems
    searchIcon: "󰅎"
    focusWhenVisible: clipboardWindow.shell.clipboardOpen

    itemText: function(item) { return item.display || "" }
    itemIcon: function(item) { return "󰆒" }
    highlightedText: function(text) { return clipboardWindow.highlightedClipText(text) }

    onQueryEdited: query => clipboardWindow.clipQuery = query
    onAccepted: item => clipboardWindow.copyItem(item)
    onBack: clipboardWindow.shell.closeClipboard()
    onClearRequested: clipboardWindow.clipQuery = ""
  }
}
