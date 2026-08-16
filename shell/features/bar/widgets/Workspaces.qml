pragma ComponentBehavior: Bound

import QtQuick
import qs
import Quickshell.Hyprland

Item {
  id: root
  property string monitorName: ""

  // unique list of workspaces that are occupied
  readonly property var occupiedWorkspaces: {
    const ids = [];

    for (const toplevel of Hyprland.toplevels.values) {
      const workspaceId = toplevel.workspace?.id ?? 0;
      const monitorName = toplevel.monitor?.name ?? "";

      if (workspaceId > 0 && workspaceId <= 9 && monitorName === root.monitorName && !ids.includes(workspaceId))
        ids.push(workspaceId);
    }

    return ids;
  }

  // workspaces that exist on the current monitor we are viewing
  readonly property var workspaceIds: {
    const ids = [];

    for (const workspace of Hyprland.workspaces.values) {
      const workspaceId = workspace.id;
      const belongsToMonitor = workspace.monitor?.name === root.monitorName;
      const shouldDisplay = workspaceId <= 6 || workspace.focused || root.occupiedWorkspaces.includes(workspaceId);

      if (workspaceId > 0 && workspaceId <= 9 && belongsToMonitor && shouldDisplay)
        ids.push(workspaceId);
    }

    return ids;
  }

  // getting the hyprland monitor information
  readonly property var hyprlandMonitor: Hyprland.monitors.values.find(hyprlandMonitor => {
    return hyprlandMonitor.name === root.monitorName;
  })

  // which workspace we are currently focused on
  readonly property int activeWorkspaceId: root.hyprlandMonitor?.activeWorkspace?.id ?? 0

  implicitWidth: workspaceRow.implicitWidth
  implicitHeight: workspaceRow.implicitHeight

  Row {
    id: workspaceRow
    anchors.centerIn: parent

    spacing: 4

    Repeater {
      model: root.workspaceIds

      Rectangle {
        id: workspaceItem
        required property int modelData

        // conditional styling
        property int workspaceId: workspaceItem.modelData
        property bool hovered: mouseArea.containsMouse

        property bool isActive: root.activeWorkspaceId === workspaceId
        property bool isOccupied: root.occupiedWorkspaces.includes(workspaceId)

        // make it square
        width: workspaceNumber.implicitWidth + 12
        height: workspaceNumber.implicitHeight + 2

        color: "transparent"
        radius: 4 // little bit of rounding

        border.width: workspaceItem.isActive ? 1 : 0
        border.color: Colors.foreground

        // number displays
        Text {
          id: workspaceNumber

          anchors.centerIn: parent
          text: workspaceItem.workspaceId
          color: workspaceItem.isActive || workspaceItem.isOccupied ? Colors.foreground : Colors.muted
          font.family: "monospace"
          font.pixelSize: 14
        }

        // clickable workspace indicators
        MouseArea {
          id: mouseArea

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            Hyprland.dispatch('hl.dsp.focus({ workspace =' + (workspaceItem.workspaceId) + ' })');
          }
        }
      }
    }
  }
}
