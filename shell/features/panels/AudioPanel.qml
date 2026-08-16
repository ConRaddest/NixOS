import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
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
  implicitHeight: mainLayout.implicitHeight + 40
  color: "transparent"

  // Track candidate sinks/sources from the global service so Pipewire updates work correctly
  PwObjectTracker {
    objects: AudioService.candidateSinks
  }
  PwObjectTracker {
    objects: AudioService.candidateSources
  }

  PwNodePeakMonitor {
    id: outputPeakMon
    node: AudioService.activeSink
    enabled: !!AudioService.activeSink && root.visible
  }

  PwNodePeakMonitor {
    id: inputPeakMon
    node: AudioService.activeSource
    enabled: !!AudioService.activeSource && root.visible
  }

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
      id: mainLayout

      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 20
      spacing: 16

      // --- Header ---
      Header {
        Layout.fillWidth: true
        icon: AudioService.outputIcon
        heading: "Audio"
        subheading: {
          if (AudioService.outputMuted || AudioService.outputVolume === 0.0)
            return "SILENCED";

          var pct = Math.round(AudioService.outputVolume * 100);
          if (pct <= 30)
            return pct + "% • JAZZ BALLAD";
          if (pct <= 70)
            return pct + "% • EASY LISTENING";
          if (pct <= 100)
            return pct + "% • ROCK CONCERT";
          return pct + "% • TINNITUS BABY";
        }

        actionComponent: Component {
          Switch {
            checked: !AudioService.outputMuted
            onToggled: {
              AudioService.toggleOutputMute();
            }
          }
        }
      }

      Divider {
        Layout.fillWidth: true
      }

      // --- Output / Speaker Section ---
      Slider {
        id: outputSlider
        Layout.fillWidth: true
        title: "OUTPUT"
        from: 0.0
        to: 1.5
        value: AudioService.outputVolume
        onMoved: function (val) {
          AudioService.setOutputVolume(val);
        }

        Binding {
          target: outputSlider
          property: "value"
          value: AudioService.outputVolume
          when: !outputSlider.pressed
        }
      }

      SelectList {
        Layout.fillWidth: true
        selectedId: AudioService.activeSink ? String(AudioService.activeSink.id) : ""
        model: AudioService.sinkList
        defaultIcon: "󰓃"
        onItemSelected: function (id) {
          AudioService.setDefaultSink(id);
        }
      }

      Divider {
        Layout.fillWidth: true
      }

      // --- Input / Microphone Section ---
      Slider {
        id: inputSlider
        Layout.fillWidth: true
        title: "INPUT"
        from: 0.0
        to: 1.5
        value: AudioService.inputVolume
        showOutput: true
        outputValue: inputPeakMon.peak || 0.0
        onMoved: function (val) {
          AudioService.setInputVolume(val);
        }

        Binding {
          target: inputSlider
          property: "value"
          value: AudioService.inputVolume
          when: !inputSlider.pressed
        }
      }

      SelectList {
        Layout.fillWidth: true
        selectedId: AudioService.activeSource ? String(AudioService.activeSource.id) : ""
        model: AudioService.sourceList
        defaultIcon: "󰍬"
        onItemSelected: function (id) {
          AudioService.setDefaultSource(id);
        }
      }
    }
  }
}
