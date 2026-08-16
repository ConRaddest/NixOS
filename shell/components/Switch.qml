import QtQuick
import qs

Item {
  id: control

  // Exposed Properties
  property bool checked: false
  property color activeColor: Colors.dark_foreground
  property color inactiveColor: Colors.muted
  property color handleColor: Colors.foreground
  property int trackPadding: 3

  signal toggled

  implicitWidth: 44
  implicitHeight: 22

  // Pure click handler that does NOT mutate 'checked' locally
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: control.toggled()
  }

  // --- Track Background ---
  Rectangle {
    anchors.fill: parent
    radius: 0
    color: control.checked ? control.activeColor : control.inactiveColor

    Behavior on color {
      ColorAnimation {
        duration: 150
      }
    }
  }

  // --- Square Handle / Indicator ---
  Rectangle {
    x: control.checked ? parent.width - width - control.trackPadding : control.trackPadding
    y: (parent.height - height) / 2
    width: control.implicitHeight - (control.trackPadding * 2)
    height: control.implicitHeight - (control.trackPadding * 2)
    radius: 0
    color: control.handleColor

    Behavior on x {
      NumberAnimation {
        duration: 150
        easing.type: Easing.InOutQuad
      }
    }
  }
}
