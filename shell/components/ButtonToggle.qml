pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs

ColumnLayout {
  id: root

  // Section label above the button group
  property string title: "POWER PROFILE"
  property string selected: "Performance"
  property var options: []

  spacing: 8
  Layout.fillWidth: true

  // Section Label
  Text {
    text: root.title
    font.capitalization: Font.AllUppercase
    color: Colors.dark_foreground
    font.family: "monospace"
    font.pixelSize: 11
  }

  // Row of Buttons
  RowLayout {
    Layout.fillWidth: true
    spacing: 8

    Repeater {
      model: root.options

      Button {
        required property var modelData

        text: modelData.label ?? ""
        icon: modelData.icon ?? ""
        active: root.selected === modelData.id

        onClicked: {
          root.selected = modelData.id;
        }
      }
    }
  }
}
