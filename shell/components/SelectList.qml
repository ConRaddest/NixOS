import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

ColumnLayout {
  id: root

  // Data model expects objects with: { id: string, label: string, icon: string (optional) }
  property var model: []
  property string selectedId: ""
  property string defaultIcon: "󰓃"

  // Define max height to enable scrolling (default: 160px)
  property real maxHeight: 78

  signal itemSelected(string id, var item)

  spacing: 0
  Layout.fillWidth: true

  // --- Scrollable Container ---
  ScrollView {
    Layout.fillWidth: true
    Layout.maximumHeight: root.maxHeight

    // Auto-calculate implicit height based on items up to the maximum cap
    implicitHeight: Math.min(contentColumn.implicitHeight, root.maxHeight)

    // Clip content so overflowing items don't leak outside the list area
    clip: true

    // Hide default scrollbar track for clean UI styling
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      id: contentColumn
      width: parent.width

      Repeater {
        model: root.model

        delegate: Rectangle {
          id: itemRect

          required property var modelData
          required property int index

          readonly property bool isSelected: modelData.id === root.selectedId

          Layout.fillWidth: true
          implicitHeight: 36
          radius: 0

          // Background hover/selection states
          color: {
            if (isSelected) {
              return Colors.selection;
            } else if (mouseArea.containsMouse) {
              return Colors.selection;
            } else {
              return "transparent";
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            anchors.rightMargin: 10
            spacing: 10

            Text {
              text: itemRect.modelData.icon || root.defaultIcon
              color: Colors.foreground
              font.family: "monospace"
              font.pixelSize: 14
              Layout.alignment: Qt.AlignVCenter
            }

            Text {
              text: itemRect.modelData.label
              color: Colors.foreground
              font.family: "monospace"
              font.pixelSize: 12
              font.bold: itemRect.isSelected
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              elide: Text.ElideRight
            }
          }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
              root.selectedId = itemRect.modelData.id;
              root.itemSelected(itemRect.modelData.id, itemRect.modelData);
            }
          }
        }
      }
    }
  }
}
