pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.services

Item {
  id: root

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

  function setOutputVolume(val) {
    if (!activeSink)
      return;

    var targetVol = val;
    if (targetVol > 1.5 && targetVol <= 150)
      targetVol = targetVol / 100.0;
    var clamped = Math.max(0.0, Math.min(1.5, targetVol));

    if (activeSink.audio) {
      activeSink.audio.volume = clamped;
    }

    if (activeSink.id !== undefined) {
      var pct = Math.round(clamped * 100) + "%";
      Quickshell.execDetached(["wpctl", "set-volume", "--limit", "1.5", String(activeSink.id), pct]);
    }

    root.osdTriggered("Volume", clamped, outputIcon);
  }

  function setInputVolume(val) {
    if (!activeSource)
      return;

    var targetVol = val;
    if (targetVol > 1.5 && targetVol <= 150)
      targetVol = targetVol / 100.0;
    var clamped = Math.max(0.0, Math.min(1.5, targetVol));

    if (activeSource.audio) {
      activeSource.audio.volume = clamped;
    }

    if (activeSource.id !== undefined) {
      var pct = Math.round(clamped * 100) + "%";
      Quickshell.execDetached(["wpctl", "set-volume", "--limit", "1.5", String(activeSource.id), pct]);
    }

    root.osdTriggered("Microphone", clamped, inputIcon);
  }

  function toggleOutputMute() {
    if (!activeSink)
      return;

    var newMuteState = !outputMuted;

    if (activeSink.audio) {
      activeSink.audio.muted = newMuteState;
    }

    if (activeSink.id !== undefined) {
      var muteVal = newMuteState ? "1" : "0";
      Quickshell.execDetached(["wpctl", "set-mute", String(activeSink.id), muteVal]);
    }

    root.osdTriggered("Volume", outputVolume, outputIcon);
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

  property Item _internal: Item {
    Timer {
      id: refreshTimer
      interval: 75
      repeat: false
      onTriggered: root.rebuildSnapshots()
    }

    Connections {
      target: root
      function onCandidateSinksChanged() {
        refreshTimer.restart();
      }
      function onCandidateSourcesChanged() {
        refreshTimer.restart();
      }
    }
  }

  Component.onCompleted: rebuildSnapshots()
}
