import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import "../../components"

PopupWindow {
  id: root

  property Item anchorItem
  property int barGap: 8
  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null

  function toggle() {
    visible = !visible;
  }

  visible: false
  implicitWidth: 460
  implicitHeight: 285
  color: "transparent"

  grabFocus: true

  anchor {
    window: root.anchorWindow
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    adjustment: PopupAdjustment.Slide

    onAnchoring: {
      if (!root.anchorItem || !root.anchorWindow)
        return;

      const point = root.anchorWindow.contentItem.mapFromItem(root.anchorItem, root.anchorItem.width - root.implicitWidth, root.anchorItem.height + root.barGap);
      anchor.rect.x = Math.round(point.x);
      anchor.rect.y = Math.round(point.y);
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.background
    border.color: Colors.accent
    border.width: 2
    radius: 0

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 16

      Header {
        Layout.fillWidth: true
        icon: "󰍺"
        heading: "Display"
        subheading: {
          const val = Math.round(MonitorsService.brightness * 100);
          if (val < 15) {
            return "THE GLOAMING";
          } else if (val < 35) {
            return "DIM & SAVING";
          } else if (val < 60) {
            return "BALANCED GLOW";
          } else if (val < 90) {
            return "BRIGHT & CLEAR";
          } else {
            return "VISCERAL DAYLIGHT";
          }
        }
        actionComponent: Component {
          Text {
            text: Math.round(MonitorsService.brightness * 100) + "%"
            color: Colors.foreground
            font.pixelSize: 34
            font.family: "monospace"
            font.bold: true
          }
        }
      }

      Divider {}

      Slider {
        title: "BRIGHTNESS"
        value: MonitorsService.brightness
        from: 0.05
        to: 1.0

        onMoved: function (val) {
          MonitorsService.setBrightness(val);
        }
      }

      Divider {}

      ButtonToggle {
        title: "SCALE"
        selected: "100"
        options: [
          {
            id: "100",
            label: "1x"
          },
          {
            id: "133",
            label: "1.33x"
          },
          {
            id: "166",
            label: "1.66x"
          },
          {
            id: "200",
            label: "2x"
          },
          {
            id: "313",
            label: "3.13x"
          },
          {
            id: "400",
            label: "4x"
          }
        ]
      }
    }
  }
}
