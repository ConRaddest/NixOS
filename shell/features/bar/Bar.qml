import QtQuick
import QtQuick.Layouts
import Quickshell
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
    // assigns on bar per screen
    screen: modelData

    // height of the bar
    implicitHeight: 30

    // top of the screen
    anchors {
      top: true
      left: true
      right: true
    }

    PowerPanel {
      id: powerPanel
      anchorItem: batteryWidget
    }

    MonitorsPanel {
      id: monitorsPanel
      anchorItem: batteryWidget
    }

    AudioPanel {
      id: audioPanel
      anchorItem: audioWidget
    }

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

        // middle
        BarWidget {
          Datetime {}
        }

        // right
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
            audioPanel.toggle();
          }
          Media {}
        }

        BarWidget {
          id: monitorsWidget

          variant: "icon"
          onClicked: {
            monitorsPanel.toggle();
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
            powerPanel.toggle();
          }

          Battery {}
        }
      }
    }
  }
}
