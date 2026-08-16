import QtQuick
import QtQuick.Layouts
import qs

Item {
  id: root

  property string label: ""
  property bool hovered: mouseArea.containsMouse
  property bool toggled: false
  property string variant: "text"

  // passing children as contentRow
  default property alias content: contentRow.data

  signal clicked

  // Fill bar height so bottom border aligns with bar bottom in RowLayout.
  Layout.fillHeight: true

  implicitWidth: variant == "text" ? contentRow.implicitWidth : 25
  implicitHeight: contentRow.implicitHeight + 9

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    radius: 0

    // bottom highlight border
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      color: root.hovered || root.toggled ? Colors.accent : "transparent"
      radius: parent.radius
      height: 2
    }
  }

  Row {
    id: contentRow
    anchors.centerIn: parent

    Text {
      text: root.label
      color: Colors.foreground
      visible: root.label.length > 0
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.clicked();
    }
  }
}
