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

  anchor {
    window: root.anchorWindow
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    adjustment: PopupAdjustment.Slide

    onAnchoring: {
      if (!anchorItem || !root.anchorWindow)
        return;

      // 1. Map widget position to window coordinates
      const mapped = anchorItem.mapToItem(root.anchorWindow.contentItem, 0, 0);

      // 2. Calculate X so panel's right edge aligns with widget's right edge
      anchor.rect.x = Math.round(mapped.x + anchorItem.width - root.implicitWidth);
      anchor.rect.y = Math.round(mapped.y + anchorItem.height + root.barGap);
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.background
    border.color: Colors.accent
    border.width: 2
    radius: 0

    MouseArea {
      anchors.fill: parent
      onPressed: mouse => mouse.accepted = true
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 16

      Header {
        Layout.fillWidth: true
        icon: BatteryService.batteryIcon
        heading: "Battery"
        subheading: {
          if (BatteryService.chargePercent < 15) {
            return "PLUG IN NOW";
          } else if (BatteryService.chargePercent < 35) {
            return "DRAINING FAST";
          } else if (BatteryService.chargePercent < 60) {
            return "GOING STRONG";
          } else if (BatteryService.chargePercent < 90) {
            return "WELL CHARGED";
          } else {
            return "TOPPED OFF";
          }
        }
        actionComponent: Component {
          Text {
            text: BatteryService.chargePercent + "%"
            color: Colors.foreground
            font.pixelSize: 34
            font.family: "monospace"
            font.bold: true
          }
        }
      }

      Progress {
        Layout.fillWidth: true
        value: BatteryService.chargePercent / 100
      }

      InfoGrid {
        columns: 2
        model: [
          {
            key: "Battery size",
            value: BatteryService.batterySizeWh + "Wh"
          },
          {
            key: "Charge limit",
            value: "100%"
          },
          {
            key: "Charge cycles",
            value: BatteryService.chargeCycles
          },
          {
            key: "Battery state",
            value: BatteryService.batteryState
          }
        ]
      }

      Divider {}

      ButtonToggle {
        title: "POWER PROFILE"
        selected: BatteryService.powerProfile
        options: [
          {
            id: "PowerSaver",
            label: "Power-saver",
            icon: ""
          },
          {
            id: "Balanced",
            label: "Balanced",
            icon: "󰊚"
          },
          {
            id: "Performance",
            label: "Performance",
            icon: "󰓅"
          }
        ]
        onSelectedChanged: {
          BatteryService.setPowerProfile(selected);
        }
      }
    }
  }
}
