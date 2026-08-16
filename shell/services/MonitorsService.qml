pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property real brightness: 1.0

  // Signal to notify the OSD popup
  signal osdTriggered(string type, real value, string icon)

  function setBrightness(percent) {
    const clamped = Math.max(0.05, Math.min(1.0, percent));
    root.brightness = clamped;

    brightnessProc.command = ["brightnessctl", "set", Math.round(clamped * 100) + "%"];
    brightnessProc.running = true;

    // Trigger OSD
    root.osdTriggered("Brightness", root.brightness, "");
  }

  function readBrightness() {
    getBrightnessProc.running = true;
  }

  Process {
    id: brightnessProc
  }

  Process {
    id: getBrightnessProc
    command: ["brightnessctl", "info"]
    stdout: SplitParser {
      onRead: data => {
        const match = data.match(/\((\d+)%\)/);
        if (match && match[1]) {
          root.brightness = parseInt(match[1]) / 100.0;
        }
      }
    }
  }

  Component.onCompleted: {
    root.readBrightness();
  }
}
