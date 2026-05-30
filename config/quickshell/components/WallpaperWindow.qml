import QtQuick
import Quickshell
import Qt.labs.folderlistmodel

FloatingWindow {
  id: wallpaper

  required property var shell
  property string selectedPath: wallpaperList.currentItem ? wallpaperList.currentItem.filePath : ""

  visible: shell.wallpaperOpen
  title: "wallpaper-picker"
  implicitWidth: 760
  implicitHeight: 460
  color: shell.bg

  function fileName(path) {
    const parts = String(path).split("/")
    return parts[parts.length - 1]
  }

  function applyWallpaper(path) {
    if (!path || path === "")
      return

    const quoted = shell.shellQuote(path)
    shell.runDetached("$HOME/.config/quickshell/scripts/apply-wallpaper.sh " + quoted)
    shell.wallpaperOpen = false
  }

  FolderListModel {
    id: wallpaperModel
    folder: wallpaper.shell.homeDir + "/OS/wallpapers"
    nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
    showDirs: false
    sortField: FolderListModel.Name
  }

  Rectangle {
    anchors.fill: parent
    color: wallpaper.shell.bg

    Column {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10

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

      Row {
        width: parent.width
        height: parent.height - 34 - parent.spacing
        spacing: 10

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

  onVisibleChanged: if (visible) wallpaperList.forceActiveFocus()

  // Hyprland's `killactive` (SUPER+W) closes the backing window directly, so
  // keep Quickshell state in sync for the next toggle/open.
  onClosed: wallpaper.shell.wallpaperOpen = false
}
