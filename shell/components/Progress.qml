import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
  id: root

  // Exposed properties
  property real value: 0.79 // Value between 0.0 and 1.0 (79%)

  // Customization props (optional overrides)
  property color trackColor: Colors.lighter_background
  property color fillColor: Colors.foreground

  // Layout sizing defaults
  implicitWidth: 300
  implicitHeight: 10
  Layout.fillWidth: true

  // Track styling
  color: trackColor
  radius: height / 2

  // Progress Fill
  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    // Calculate width relative to the parent track
    width: Math.min(Math.max(root.value, 0.0), 1.0) * parent.width

    color: root.fillColor
    radius: parent.radius

    // Smooth transition when value updates
    Behavior on width {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }
  }
}
