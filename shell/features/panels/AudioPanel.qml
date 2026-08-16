import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
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
  // Dynamic height driven by children + margins (20 top + 20 bottom)
  implicitHeight: mainLayout.implicitHeight + 40
  color: "transparent"
  grabFocus: true

  // --- Internal Audio Service / Pipewire State ---
  QtObject {
    id: audio

    signal osdTriggered(string type, real value, string icon)

    readonly property PwNode rawDefaultSink: Pipewire.defaultAudioSink
    readonly property PwNode rawDefaultSource: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []

    readonly property var candidateSinks: {
      var list = [];
      if (!nodes)
        return list;
      for (var i = 0; i < nodes.length; i++) {
        var n = nodes[i];
        if (n && n.isSink && !n.isStream)
          list.push(n);
      }
      return list;
    }

    readonly property var candidateSources: {
      var list = [];
      if (!nodes)
        return list;
      for (var i = 0; i < nodes.length; i++) {
        var n = nodes[i];
        if (n && !n.isSink && !n.isStream && n.audio)
          list.push(n);
      }
      return list;
    }

    readonly property PwNode activeSink: rawDefaultSink || (candidateSinks.length > 0 ? candidateSinks[0] : null)
    readonly property PwNode activeSource: rawDefaultSource || (candidateSources.length > 0 ? candidateSources[0] : null)

    property var sinkList: []
    property var sourceList: []

    function rebuildSnapshots() {
      var sList = [];
      for (var i = 0; i < candidateSinks.length; i++) {
        var sn = candidateSinks[i];
        sList.push({
          id: String(sn.id),
          label: sn.description || sn.name || "Audio Output",
          icon: "󰓃"
        });
      }
      sinkList = sList;

      var srcList = [];
      for (var j = 0; j < candidateSources.length; j++) {
        var src = candidateSources[j];
        srcList.push({
          id: String(src.id),
          label: src.description || src.name || "Microphone Input",
          icon: "󰍬"
        });
      }
      sourceList = srcList;
    }

    readonly property real outputVolume: activeSink && activeSink.audio ? activeSink.audio.volume : 0.0
    readonly property real inputVolume: activeSource && activeSource.audio ? activeSource.audio.volume : 0.0
    readonly property bool outputMuted: activeSink && activeSink.audio ? activeSink.audio.muted : false
    readonly property bool inputMuted: activeSource && activeSource.audio ? activeSource.audio.muted : false

    readonly property string outputIcon: {
      if (outputMuted || outputVolume === 0.0)
        return "󰝟";
      if (outputVolume < 0.33)
        return "󰕿";
      if (outputVolume < 0.66)
        return "󰖀";
      return "󰕾";
    }

    readonly property string inputIcon: {
      if (inputMuted || inputVolume === 0.0)
        return "󰍭";
      return "󰍬";
    }

    // --- Updated Control Handlers inside QtObject ---
    function setOutputVolume(val) {
      if (!activeSink)
        return;

      // Allow volume scaling up to 150% (1.5)
      var targetVol = val;
      if (targetVol > 1.5 && targetVol <= 150)
        targetVol = targetVol / 100.0;
      var clamped = Math.max(0.0, Math.min(1.5, targetVol));

      if (activeSink.audio) {
        activeSink.audio.volume = clamped;
      }

      if (activeSink.id !== undefined) {
        var pct = Math.round(clamped * 100) + "%";
        // --limit 1.5 allows wpctl to raise volume above 100% up to 150%
        Quickshell.execDetached(["wpctl", "set-volume", "--limit", "1.5", String(activeSink.id), pct]);
      }

      osdTriggered("Volume", clamped, outputIcon);
    }

    function setInputVolume(val) {
      if (!activeSource)
        return;

      var targetVol = val;
      if (targetVol > 1.0)
        targetVol = targetVol / 100.0;
      var clamped = Math.max(0.0, Math.min(1.0, targetVol));

      if (activeSource.audio) {
        activeSource.audio.volume = clamped;
      }

      if (activeSource.id !== undefined) {
        var pct = Math.round(clamped * 100) + "%";
        Quickshell.execDetached(["wpctl", "set-volume", String(activeSource.id), pct]);
      }

      osdTriggered("Microphone", clamped, inputIcon);
    }

    function toggleOutputMute() {
      if (!activeSink)
        return;

      var newMuteState = !outputMuted;

      // 1. Mutate native Pipewire audio object directly if available
      if (activeSink.audio) {
        activeSink.audio.muted = newMuteState;
      }

      // 2. Pass explicit state ("1" for mute, "0" for unmute) rather than "toggle"
      if (activeSink.id !== undefined) {
        var muteVal = newMuteState ? "1" : "0";
        Quickshell.execDetached(["wpctl", "set-mute", String(activeSink.id), muteVal]);
      }

      osdTriggered("Volume", outputVolume, outputIcon);
    }

    function toggleInputMute() {
      if (!activeSource)
        return;

      var newMuteState = !inputMuted;

      if (activeSource.audio) {
        activeSource.audio.muted = newMuteState;
      }

      if (activeSource.id !== undefined) {
        var muteVal = newMuteState ? "1" : "0";
        Quickshell.execDetached(["wpctl", "set-mute", String(activeSource.id), muteVal]);
      }

      osdTriggered("Microphone", inputVolume, inputIcon);
    }

    function setDefaultSink(nodeId) {
      var numericId = Number(nodeId);
      for (var i = 0; i < candidateSinks.length; i++) {
        if (candidateSinks[i].id === numericId) {
          var node = candidateSinks[i];
          Pipewire.preferredDefaultAudioSink = node;
          if (node.id !== undefined) {
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)]);
          }
          break;
        }
      }
    }

    function setDefaultSource(nodeId) {
      var numericId = Number(nodeId);
      for (var i = 0; i < candidateSources.length; i++) {
        if (candidateSources[i].id === numericId) {
          var node = candidateSources[i];
          Pipewire.preferredDefaultAudioSource = node;
          if (node.id !== undefined) {
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)]);
          }
          break;
        }
      }
    }
  }

  PwObjectTracker {
    objects: audio.candidateSinks
  }
  PwObjectTracker {
    objects: audio.candidateSources
  }

  PwNodePeakMonitor {
    id: outputPeakMon
    node: audio.activeSink
    enabled: !!audio.activeSink && root.visible
  }

  PwNodePeakMonitor {
    id: inputPeakMon
    node: audio.activeSource
    enabled: !!audio.activeSource && root.visible
  }

  Timer {
    id: refreshTimer
    interval: 75
    repeat: false
    onTriggered: audio.rebuildSnapshots()
  }

  Connections {
    target: audio
    function onCandidateSinksChanged() {
      refreshTimer.restart();
    }
    function onCandidateSourcesChanged() {
      refreshTimer.restart();
    }
  }

  Component.onCompleted: audio.rebuildSnapshots()

  // qmllint disable missing-type unqualified unresolved-type
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
  // qmllint enable missing-type unqualified unresolved-type

  Rectangle {
    anchors.fill: parent
    color: Colors.background
    border.color: Colors.accent
    border.width: 2
    radius: 0

    ColumnLayout {
      id: mainLayout

      // Pin top/left/right so width stays bounded, but height flows freely
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 20
      spacing: 16

      // --- Header ---
      Header {
        Layout.fillWidth: true
        icon: audio.outputIcon
        heading: "Audio"
        subheading: {
          if (audio.outputMuted || audio.outputVolume === 0.0)
            return "SILENCED";

          var pct = Math.round(audio.outputVolume * 100);
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
            checked: !audio.outputMuted
            onToggled: {
              audio.toggleOutputMute();
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
        to: 1.5  // Max 150%
        value: audio.outputVolume
        onMoved: function (val) {
          audio.setOutputVolume(val);
        }

        Binding {
          target: outputSlider
          property: "value"
          value: audio.outputVolume
          when: !outputSlider.pressed
        }
      }

      SelectList {
        Layout.fillWidth: true
        selectedId: audio.activeSink ? String(audio.activeSink.id) : ""
        model: audio.sinkList
        defaultIcon: "󰓃"
        onItemSelected: function (id) {
          audio.setDefaultSink(id);
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
        value: audio.inputVolume
        showOutput: true
        outputValue: inputPeakMon.peak || 0.0
        onMoved: function (val) {
          audio.setInputVolume(val);
        }

        Binding {
          target: inputSlider
          property: "value"
          value: audio.inputVolume
          when: !inputSlider.pressed
        }
      }

      SelectList {
        Layout.fillWidth: true
        selectedId: audio.activeSource ? String(audio.activeSource.id) : ""
        model: audio.sourceList
        defaultIcon: "󰍬"
        onItemSelected: function (id) {
          audio.setDefaultSource(id);
        }
      }
    }
  }
}
