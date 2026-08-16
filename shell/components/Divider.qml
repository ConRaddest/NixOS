import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
  id: root

  // Properties
  property bool vertical: false
  property real thickness: 1
  property color dividerColor: Colors.muted

  // Dynamic layout sizing based on orientation
  implicitWidth: vertical ? thickness : 0
  implicitHeight: vertical ? 0 : thickness

  Layout.fillWidth: !vertical
  Layout.fillHeight: vertical

  color: dividerColor
}
