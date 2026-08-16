pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
  id: root

  signal osdTriggered(string type, real value, string icon)

  // Direct Pipewire Node Proxies
  readonly property PwNode rawDefaultSink: Pipewire.defaultAudioSink
  readonly property PwNode rawDefaultSource: Pipewire.defaultAudioSource
  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []

  // Safe Filtered Candidates
  readonly property var candidateSinks: {
    var list = [];
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i];
      if (n && n.isSink && !n.isStream)
        list.push(n);
    }
    return list;
  }

  readonly property var candidateSources: {
    var list = [];
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i];
      if (n && !n.isSink && !n.isStream && n.audio)
        list.push(n);
    }
    return list;
  }

  // Active Default Sinks & Sources
  readonly property PwNode activeSink: rawDefaultSink || (candidateSinks.length > 0 ? candidateSinks[0] : null)
  readonly property PwNode activeSource: rawDefaultSource || (candidateSources.length > 0 ? candidateSources[0] : null)

  // Object Trackers keep internal Pipewire object states alive
  PwObjectTracker {
    objects: root.candidateSinks
  }
  PwObjectTracker {
    objects: root.candidateSources
  }

  // Peak Monitor components natively integrated with Pipewire
  PwNodePeakMonitor {
    id: outputPeakMon
    node: root.activeSink
    enabled: !!root.activeSink
  }

  PwNodePeakMonitor {
    id: inputPeakMon
    node: root.activeSource
    enabled: !!root.activeSource
  }

  // Live Readouts
  readonly property real outputVolume: activeSink && activeSink.audio ? activeSink.audio.volume : 0.0
  readonly property real inputVolume: activeSource && activeSource.audio ? activeSource.audio.volume : 0.0
  readonly property bool outputMuted: activeSink && activeSink.audio ? activeSink.audio.muted : false
  readonly property bool inputMuted: activeSource && activeSource.audio ? activeSource.audio.muted : false

  readonly property real outputPeak: outputPeakMon.peak || 0.0
  readonly property real inputPeak: inputPeakMon.peak || 0.0

  // Snapshot lists for SelectList UI components
  property var sinkList: []
  property var sourceList: []

  readonly property string defaultSinkId: activeSink ? String(activeSink.id) : ""
  readonly property string defaultSourceId: activeSource ? String(activeSource.id) : ""

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
    root.sinkList = sList;

    var srcList = [];
    for (var j = 0; j < candidateSources.length; j++) {
      var src = candidateSources[j];
      srcList.push({
        id: String(src.id),
        label: src.description || src.name || "Microphone Input",
        icon: "󰍬"
      });
    }
    root.sourceList = srcList;
  }

  // Refresh snapshots on timer to avoid mid-frame array mutation crashes
  Timer {
    id: refreshTimer
    interval: 75
    repeat: false
    onTriggered: root.rebuildSnapshots()
  }

  onCandidateSinksChanged: refreshTimer.restart()
  onCandidateSourcesChanged: refreshTimer.restart()

  Component.onCompleted: rebuildSnapshots()

  // Actions
  function setOutputVolume(val) {
    if (!activeSink || !activeSink.audio)
      return;
    var clamped = Math.max(0.0, Math.min(1.0, val));
    activeSink.audio.volume = clamped;
    root.osdTriggered("Volume", clamped, outputIcon);
  }

  function setInputVolume(val) {
    if (!activeSource || !activeSource.audio)
      return;
    var clamped = Math.max(0.0, Math.min(1.0, val));
    activeSource.audio.volume = clamped;
    root.osdTriggered("Microphone", clamped, inputIcon);
  }

  function toggleOutputMute() {
    if (!activeSink || !activeSink.audio)
      return;
    activeSink.audio.muted = !activeSink.audio.muted;
    root.osdTriggered("Volume", outputVolume, outputIcon);
  }

  function toggleInputMute() {
    if (!activeSource || !activeSource.audio)
      return;
    activeSource.audio.muted = !activeSource.audio.muted;
    root.osdTriggered("Microphone", inputVolume, inputIcon);
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
}
