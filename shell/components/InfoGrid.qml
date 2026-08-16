import QtQuick
import QtQuick.Layouts
import qs

GridLayout {
  id: root

  // Array of key-value objects, e.g.:
  // [{ key: "Battery size", value: "69Wh" }, { key: "Charge limit", value: "75-80%" }]
  property var model: []

  // Defaults to 2 columns, but can be overridden
  columns: 2
  columnSpacing: 24
  rowSpacing: 10
  Layout.fillWidth: true

  Repeater {
    model: root.model

    delegate: RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: modelData.key ?? ""
        color: Colors.dark_foreground
        font.family: "monospace"
        font.pixelSize: 13
        Layout.fillWidth: true
      }

      Text {
        text: modelData.value ?? ""
        color: Colors.foreground
        font.family: "monospace"
        font.pixelSize: 13
      }
    }
  }
}
