pragma Singleton

import QtQuick

QtObject {
  readonly property SystemPalette active: SystemPalette {
    colorGroup: SystemPalette.Active
  }

  readonly property color background: active.window
  readonly property color foreground: active.windowText
  readonly property color surface: active.base
  readonly property color surfaceAlternate: active.alternateBase
  readonly property color text: active.text
  readonly property color textMuted: active.placeholderText
  readonly property color button: active.button
  readonly property color buttonText: active.buttonText
  readonly property color primary: active.highlight
  readonly property color onPrimary: active.highlightedText
  readonly property color accent: active.accent
  readonly property color border: active.mid
  readonly property color shadow: active.shadow
  readonly property color tooltip: active.base
  readonly property color tooltipText: active.text
}
