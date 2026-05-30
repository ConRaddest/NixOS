import QtQuick
import Quickshell
import Quickshell.Io

// ─── Clipboard history window ─────────────────────────────────────────────────
// Floating keyboard-driven picker for wl-clipboard history via cliphist.
// Selecting an item pipes it back through cliphist decode and into wl-copy.
FloatingWindow {
  id: clipboardWindow

  required property var shell

  property string clipQuery: ""
  property var clipItems: []

  property alias clipInputItem: clipInput
  property alias clipListItem:  clipList

  readonly property var filteredItems: getFilteredItems()

  screen: shell.launcherScreen
  visible: shell.clipboardOpen
  title: "shell-clipboard"
  color: shell.bg

  onVisibleChanged: {
    if (visible) {
      clipQuery = ""
      if (clipInput) { clipInput.text = ""; clipInput.forceActiveFocus() }
      if (clipList)  clipList.currentIndex = 0
      fetchProcess.running = false
      fetchProcess.command = ["bash", "-c", "cliphist list 2>/dev/null || true"]
      fetchProcess.running = true
    } else {
      clipQuery = ""
    }
  }

  onFilteredItemsChanged: {
    if (clipList) clipList.currentIndex = 0
  }

  // ─── Processes ─────────────────────────────────────────────────────────────

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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  function getFilteredItems() {
    const q = clipQuery.trim().toLowerCase()
    if (q === "") return clipItems
    return clipItems.filter(item => item.display.toLowerCase().includes(q))
  }

  function copyItem(item) {
    copyProcess.command = ["bash", "-c", "printf '%s\\n' " + shellQuote(item.raw) + " | cliphist decode | wl-copy"]
    copyProcess.running = true
    shell.closeClipboard()
  }

  function highlightedText(text) {
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

  // ─── UI ────────────────────────────────────────────────────────────────────

  Rectangle {
    anchors.fill: parent
    color: clipboardWindow.shell.bg

    Column {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10

      // ─── Search input ────────────────────────────────────────────────────
      Rectangle {
        width: parent.width
        height: 42
        radius: 5
        color: "transparent"
        border.color: clipboardWindow.shell.surfaceLight
        border.width: 2

        Text {
          id: searchIcon
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          width: 20
          text: "󰅎"
          color: clipboardWindow.shell.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 16
          font.weight: Font.Bold
          horizontalAlignment: Text.AlignHCenter
        }

        TextInput {
          id: clipInput
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.left: searchIcon.right
          anchors.right: parent.right
          anchors.margins: 4
          leftPadding: 8
          rightPadding: 10
          verticalAlignment: TextInput.AlignVCenter
          focus: clipboardWindow.shell.clipboardOpen
          color: clipboardWindow.shell.fg
          selectionColor: clipboardWindow.shell.accent
          selectedTextColor: clipboardWindow.shell.bg
          font.family: "monospace"
          font.pixelSize: 15
          font.weight: Font.Bold

          Rectangle {
            anchors.fill: parent
            z: -1
            color: clipboardWindow.shell.bg
          }

          onTextChanged: clipboardWindow.clipQuery = text
          Keys.onEscapePressed: clipboardWindow.shell.closeClipboard()
          Keys.onDownPressed: clipList.currentIndex = Math.min(clipList.currentIndex + 1, clipboardWindow.filteredItems.length - 1)
          Keys.onUpPressed:   clipList.currentIndex = Math.max(clipList.currentIndex - 1, 0)
          Keys.onPressed: event => {
            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_C) {
              clipInput.text = ""
              clipboardWindow.clipQuery = ""
              event.accepted = true
            }
          }
          Keys.onReturnPressed: {
            if (clipboardWindow.filteredItems.length > 0 && clipList.currentIndex >= 0)
              clipboardWindow.copyItem(clipboardWindow.filteredItems[clipList.currentIndex])
          }
        }
      }

      // ─── Item list ──────────────────────────────────────────────────────
      Rectangle {
        width: parent.width
        height: parent.height - 42 - parent.spacing
        radius: 5
        color: "transparent"
        border.color: clipboardWindow.shell.surfaceLight
        border.width: 2

        ListView {
          id: clipList
          anchors.fill: parent
          anchors.margins: 6
          clip: true
          model: clipboardWindow.filteredItems
          currentIndex: 0

          delegate: Rectangle {
            required property var modelData
            required property int index

            width: ListView.view.width
            height: 36
            color: ListView.isCurrentItem ? clipboardWindow.shell.hover : "transparent"

            Row {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              anchors.right: parent.right
              anchors.rightMargin: 8
              spacing: 12

              Item {
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  anchors.centerIn: parent
                  text: "󰆒"
                  color: clipboardWindow.shell.accent
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 15
                  font.weight: Font.Bold
                  horizontalAlignment: Text.AlignHCenter
                }
              }

              Text {
                width: parent.width - 32
                text: clipboardWindow.highlightedText(modelData.display)
                textFormat: Text.RichText
                color: clipboardWindow.shell.fg
                font.family: "monospace"
                font.pixelSize: 15
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: clipList.currentIndex = index
              onClicked: clipboardWindow.copyItem(modelData)
            }
          }
        }
      }
    }
  }
}
