pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  readonly property FileView paletteFile: FileView {
    path: Quickshell.env("HOME") + "/.config/stylix/palette.html"
    blockLoading: true
    preload: true
  }

  function palette(name) {
    const pattern = new RegExp("#" + name + " \\{ background-color: (#[0-9a-fA-F]{6})");
    const match = paletteFile.text().match(pattern);
    return match ? match[1] : "#FFFFFF";
  }

  readonly property color background: palette("base00")
  readonly property color darkBackground: palette("base01")
  readonly property color selection: palette("base02")
  readonly property color muted: palette("base03")
  readonly property color darkForeground: palette("base04")
  readonly property color foreground:  palette("base05")
  readonly property color lightForeground: palette("base06")
  readonly property color brightForeground: palette("base07")

  readonly property color red: palette("base08")
  readonly property color orange: palette("base09")
  readonly property color yellow: palette("base0A")
  readonly property color green: palette("base0B")
  readonly property color cyan: palette("base0C")
  readonly property color blue: palette("base0D")
  readonly property color magenta: palette("base0E")
  readonly property color brown: palette("base0F")
}
