import QtQuick
import Quickshell
import Qt.labs.folderlistmodel

// ─── Wallpaper picker window ─────────────────────────────────────────────────
// Lists images from ~/OS/wallpapers. Selecting one runs wallpaper.sh which
// patches hyprpaper.nix and triggers a home-manager rebuild.
FloatingWindow {
  id: wallpaper

  required property var shell

  // Tracks whichever item is highlighted in the list for the live preview.
  property string selectedPath: wallpaperList.currentItem ? wallpaperList.currentItem.filePath : ""

  visible: shell.wallpaperOpen
  title: "wallpaper-picker"
  implicitWidth: 760
  implicitHeight: 460
  color: shell.bg

  // Strip directory prefix to get just the filename for display.
  function fileName(path) {
    const parts = String(path).split("/")
    return parts[parts.length - 1]
  }

  // Invoke wallpaper.sh with the chosen path, then close the picker.
  function applyWallpaper(path) {
    if (!path || path === "") return
    shell.runDetached("$HOME/OS/quickshell/wallpaper.sh " + shell.shellQuote(path))
    shell.wallpaperOpen = false
  }

  // ─── Image source ────────────────────────────────────────────────────────
  FolderListModel {
    id: wallpaperModel
    folder: wallpaper.shell.homeDir + "/OS/wallpapers"
    nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
    showDirs: false
    sortField: FolderListModel.Name
  }

  // ─── UI ──────────────────────────────────────────────────────────────────
  Rectangle {
    anchors.fill: parent
    color: wallpaper.shell.bg

    Column {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10

      // ─── Header bar ─────────────────────────────────────────────────────
      Rectangle {
        width: parent.width
        height: 34
        radius: 5
        color: "transparent"
        border.color: wallpaper.shell.surfaceLight
        border.width: 2

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          text: "󰸉"
          color: wallpaper.shell.accent
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          font.weight: Font.Bold
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 38
          anchors.verticalCenter: parent.verticalCenter
          text: "~/OS/Wallpapers"
          color: wallpaper.shell.fg
          font.family: "monospace"
          font.pixelSize: 14
          font.weight: Font.Bold
        }
      }

      // ─── List + preview ──────────────────────────────────────────────────
      Row {
        width: parent.width
        height: parent.height - 34 - parent.spacing
        spacing: 10

        // File list — keyboard navigable, enter to apply
        Rectangle {
          width: 280
          height: parent.height
          radius: 5
          color: "transparent"
          border.color: wallpaper.shell.surfaceLight
          border.width: 2

          ListView {
            id: wallpaperList
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            model: wallpaperModel
            currentIndex: 0
            focus: wallpaper.shell.wallpaperOpen

            Keys.onEscapePressed: wallpaper.shell.wallpaperOpen = false
            Keys.onDownPressed: currentIndex = Math.min(currentIndex + 1, count - 1)
            Keys.onUpPressed: currentIndex = Math.max(currentIndex - 1, 0)
            Keys.onReturnPressed: if (currentItem) wallpaper.applyWallpaper(currentItem.filePath)

            delegate: Rectangle {
              required property string fileName
              required property string filePath
              required property int index

              width: ListView.view.width
              height: 28
              color: ListView.isCurrentItem ? wallpaper.shell.hover : "transparent"

              Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 4
                spacing: 10

                Text {
                  width: 18
                  text: "󰉏"
                  color: wallpaper.shell.accent
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 14
                  font.weight: Font.Bold
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  text: fileName
                  color: ListView.isCurrentItem ? wallpaper.shell.fg : "#b7bbcc"
                  font.family: "monospace"
                  font.pixelSize: 14
                  font.weight: Font.Bold
                  elide: Text.ElideRight
                  width: 220
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: wallpaperList.currentIndex = index
                onClicked: wallpaper.applyWallpaper(filePath)
              }
            }
          }
        }

        // Live preview — updates as the list selection moves
        Rectangle {
          width: parent.width - 280 - parent.spacing
          height: parent.height
          radius: 5
          color: "transparent"
          border.color: wallpaper.shell.surfaceLight
          border.width: 2

          Image {
            anchors.fill: parent
            anchors.margins: 8
            source: wallpaper.selectedPath ? "file://" + wallpaper.selectedPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
          }
        }
      }
    }
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  onVisibleChanged: if (visible) wallpaperList.forceActiveFocus()

  // Hyprland's killactive (SUPER+W) bypasses QML state, so sync wallpaperOpen
  // back to false when the window is closed by any means.
  onClosed: wallpaper.shell.wallpaperOpen = false
}
