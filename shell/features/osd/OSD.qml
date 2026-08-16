import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import "../../components"

PanelWindow {
  id: root

  anchors {
    bottom: true
  }
  margins {
    bottom: 60
  }

  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayershell.Layer.Overlay

  implicitWidth: 320
  implicitHeight: 64
  color: "transparent"

  // Show window surface when the timer is running or fading out
  visible: hideTimer.running || container.opacity > 0

  // OSD State
  property string title: "Brightness"
  property string icon: "󰍺"
  property real value: 0.0

  function show(typeTitle, val, iconSymbol) {
    root.title = typeTitle;
    root.value = val;
    root.icon = iconSymbol;
    hideTimer.restart();
  }

  Connections {
    target: MonitorsService

    function onOsdTriggered(type, value, icon) {
      root.show(type, value, icon);
    }
  }

  Timer {
    id: hideTimer
    interval: 2000
    repeat: false
  }

  Rectangle {
    id: container
    anchors.fill: parent
    color: Colors.background
    border.color: Colors.accent
    border.width: 1
    radius: 0

    // Animate opacity on the Rectangle item instead
    opacity: hideTimer.running ? 1.0 : 0.0
    Behavior on opacity {
      NumberAnimation {
        duration: 150
        easing.type: Easing.InOutQuad
      }
    }

    RowLayout {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 16

      Text {
        text: root.icon
        color: Colors.foreground
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        Layout.alignment: Qt.AlignVCenter
      }

      Progress {
        Layout.fillWidth: true
        value: root.value
      }
      Text {
        text: Math.round(root.value * 100) + "%"
        color: Colors.foreground
        font.family: "monospace"
        font.pixelSize: 14
        font.bold: true
      }
    }
  }
}
