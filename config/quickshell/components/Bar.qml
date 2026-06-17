import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// ─── Bar window ──────────────────────────────────────────────────────────────
// Anchored full-width panel at the top of each monitor.
PanelWindow {
    id: bar

    required property var shell

    anchors {
        top: true
        left: true
        right: true
    }

    visible: shell.barVisible
    implicitHeight: 28
    exclusiveZone: shell.barVisible ? 28 : 0
    color: "#66000000"
    WlrLayershell.namespace: "bar"
    WlrLayershell.layer: WlrLayer.Bottom

    // ─── Inline component: StatusPill ────────────────────────────────────────
    // Small clickable status indicator used in the right section of the bar.
    component StatusPill: Rectangle {
        id: pill

        required property var shell
        property string text: ""
        property string textColor: pill.shell.text
        property int fontPixelSize: 14
        property bool clickable: false
        signal clicked

        width: label.implicitWidth + 14
        height: 24
        radius: 6
        color: "transparent"

        Text {
            id: label
            anchors.centerIn: parent
            text: pill.text
            color: pill.textColor
            font.family: pill.shell.monoFont
            font.pixelSize: pill.fontPixelSize
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#ff000000"
                shadowBlur: 1
                shadowVerticalOffset: 2
                shadowHorizontalOffset: 0
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: pill.clickable
            hoverEnabled: pill.clickable
            cursorShape: pill.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: pill.clicked()
        }
    }

    // ─── Monitor binding ─────────────────────────────────────────────────────
    // Find the Hyprland monitor whose name matches this bar's screen.
    readonly property HyprlandMonitor hyprMonitor: {
        for (const m of Hyprland.monitors.values) {
            if (m.name === bar.screen.name)
                return m;
        }
        return null;
    }

    // Collect normal workspace IDs visible on this monitor (occupied + active).
    // Hyprland exposes special/scratchpad workspaces as negative IDs; hide those
    // from the bar instead of rendering values like -98.
    readonly property var monitorWorkspaceIds: {
        const ids = [];
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0 && ws.monitor?.name === bar.screen.name && !ids.includes(ws.id))
                ids.push(ws.id);
        }
        const active = bar.hyprMonitor?.activeWorkspace?.id;
        if (active > 0 && !ids.includes(active))
            ids.push(active);
        return ids.sort((a, b) => a - b);
    }

    // ─── Background ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#66000000"

        // ─── Left: NixOS launcher icon + workspace indicators ─────────────────
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            StatusPill {
                shell: bar.shell
                text: ""
                textColor: bar.shell.text
                fontPixelSize: 20
                clickable: true
                onClicked: bar.shell.runDetached("qs ipc call launcher open")
            }

            Repeater {
                model: bar.monitorWorkspaceIds

                Rectangle {
                    required property int modelData

                    readonly property bool active: (Hyprland.focusedWorkspace?.id || 0) === modelData

                    width: 22
                    height: 22
                    radius: 6
                    color: "transparent"
                    border.color: active ? bar.shell.text : "transparent"

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#e6000000"
                        shadowBlur: 0.9
                        shadowVerticalOffset: 1.5
                        shadowHorizontalOffset: 0
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData
                        color: bar.shell.text
                        font.family: bar.shell.monoFont
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("hl.dsp.focus({workspace=\"" + parent.modelData + "\"})")
                    }
                }
            }
        }

        // ─── Center: clock ────────────────────────────────────────────────────
        StatusPill {
            anchors.centerIn: parent
            shell: bar.shell
            text: bar.shell.timeText
            clickable: true
            onClicked: bar.shell.launchDesktop("calendar-pwa")
        }

        // ─── Right: system stats + status pills ───────────────────────────────
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StatusPill {
                shell: bar.shell
                text: bar.shell.wifiText
                clickable: true
                onClicked: bar.shell.launchTerminal("wifi-manager", "wifi-manager", "impala")
            }
            StatusPill {
                shell: bar.shell
                text: bar.shell.bluetoothText
                clickable: true
                onClicked: bar.shell.launchTerminal("bluetooth-manager", "bluetooth-manager", "bluetui")
            }
            StatusPill {
                shell: bar.shell
                text: bar.shell.volumeText
                clickable: true
                onClicked: bar.shell.launchTerminal("audio-manager", "audio-manager", "wiremix")
            }
            StatusPill {
                shell: bar.shell
                text: bar.shell.batteryText
                clickable: true
                onClicked: bar.shell.launchTerminal("performance-monitor", "performance-monitor", "btop")
            }
            StatusPill {
                shell: bar.shell
                text: "󰍛 " + bar.shell.cpuText
            }
            StatusPill {
                shell: bar.shell
                text: "  " + bar.shell.ramText
            }
        }
    }
}
