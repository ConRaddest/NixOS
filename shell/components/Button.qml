import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
  id: root

  // Exposed Properties
  property string text: ""
  property string icon: ""
  property bool active: false
  signal clicked

  // Sizing & Layout Defaults
  implicitHeight: 38
  implicitWidth: 120
  Layout.fillWidth: true

  // Colors based on state
  color: active ? Colors.selection : "transparent"
  border.color: active ? Colors.foreground : Colors.muted
  border.width: 1
  radius: 2

  // Mouse handling
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  RowLayout {
    anchors.centerIn: parent
    spacing: 8

    Text {
      visible: root.icon !== ""
      text: root.icon
      color: root.active ? Colors.foreground : Colors.muted
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 16
      Layout.alignment: Qt.AlignVCenter
    }

    Text {
      visible: root.text !== ""
      text: root.text
      color: root.active ? Colors.foreground : Colors.muted
      font.family: "monospace"
      font.pixelSize: 13
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
