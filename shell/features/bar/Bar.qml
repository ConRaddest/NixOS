import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

import "widgets"
import "../panels"
import "../../components"

Variants {
  model: Quickshell.screens

  PanelWindow {
    id: barWindow
    required property var modelData
    screen: modelData

    implicitHeight: 30

    anchors {
      top: true
      left: true
      right: true
    }

    // Helper property to check if ANY panel is currently open
    readonly property bool hasOpenPanel: powerPanel.visible || monitorsPanel.visible || audioPanel.visible

    function closeAllPanels() {
      powerPanel.visible = false;
      monitorsPanel.visible = false;
      audioPanel.visible = false;
    }

    // 1. FULLSCREEN OVERLAY (Appears only when a panel is open to catch outside clicks)
    PanelWindow {
      id: clickCatcher
      screen: barWindow.screen

      // Visible only when a panel is active
      visible: barWindow.hasOpenPanel
      color: "transparent"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      WlrLayershell.layer: WlrLayershell.Overlay
      exclusionMode: ExclusionMode.Ignore

      MouseArea {
        anchors.fill: parent
        onClicked: barWindow.closeAllPanels()
      }
    }

    // 2. YOUR PANELS
    PowerPanel {
      id: powerPanel
      anchorItem: batteryWidget
    }

    MonitorsPanel {
      id: monitorsPanel
      anchorItem: monitorsWidget // Fixed: changed batteryWidget to monitorsWidget
    }

    AudioPanel {
      id: audioPanel
      anchorItem: audioWidget
    }

    // 3. BAR CONTENT
    Rectangle {
      anchors.fill: parent
      color: Colors.background

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Workspaces {
          monitorName: barWindow.screen.name
        }

        Item {
          Layout.fillWidth: true
        }

        BarWidget {
          Datetime {}
        }

        Item {
          Layout.fillWidth: true
        }

        BarWidget {
          variant: "icon"
          Tray {}
        }

        BarWidget {
          variant: "icon"
          Bluetooth {}
        }

        BarWidget {
          id: audioWidget
          variant: "icon"
          onClicked: {
            const wasVisible = audioPanel.visible;
            barWindow.closeAllPanels();
            audioPanel.visible = !wasVisible;
          }
          Media {}
        }

        BarWidget {
          id: monitorsWidget
          variant: "icon"
          onClicked: {
            const wasVisible = monitorsPanel.visible;
            barWindow.closeAllPanels();
            monitorsPanel.visible = !wasVisible;
          }
          MonitorsWidget {}
        }

        BarWidget {
          variant: "icon"
          Notifications {}
        }

        BarWidget {
          id: batteryWidget
          variant: "icon"
          onClicked: {
            const wasVisible = powerPanel.visible;
            barWindow.closeAllPanels();
            powerPanel.visible = !wasVisible;
          }
          Battery {}
        }
      }
    }
  }
}
