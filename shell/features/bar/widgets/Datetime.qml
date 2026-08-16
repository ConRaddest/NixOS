import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

RowLayout {
  SystemClock {
    id: clock
  }

  Text {
    text: Qt.formatDateTime(clock.date, "dddd hh:mm")
    color: Colors.foreground
    font.pixelSize: 14
    font.bold: false
    font.family: "monospace"
  }
}
