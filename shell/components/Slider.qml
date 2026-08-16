import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

ColumnLayout {
  id: root

  property string title: "BRIGHTNESS"
  property real value: 1.0
  property real from: 0.0
  property real to: 1.5
  property bool showPercentage: true

  property bool showOutput: false
  property real outputValue: 0.0

  signal moved(real value)

  spacing: 6
  Layout.fillWidth: true

  RowLayout {
    Layout.fillWidth: true

    Text {
      text: root.title
      font.capitalization: Font.AllUppercase
      color: Colors.dark_foreground
      font.family: "monospace"
      font.pixelSize: 13
      Layout.fillWidth: true
    }

    Text {
      visible: root.showPercentage
      // Direct percentage calculation up to 150%
      text: Math.round(slider.value * 100) + "%"
      color: Colors.dark_foreground
      font.family: "monospace"
      font.pixelSize: 14
    }
  }

  Slider {
    id: slider

    Layout.fillWidth: true
    implicitHeight: 12
    from: root.from
    to: root.to
    value: root.value

    padding: 0
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    onMoved: {
      root.value = slider.value;
      root.moved(slider.value);
    }

    background: Rectangle {
      x: slider.leftPadding
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      implicitWidth: 200
      implicitHeight: 6
      width: slider.availableWidth
      height: implicitHeight
      radius: 2
      color: Colors.lighter_background

      Rectangle {
        width: slider.visualPosition * parent.width
        height: parent.height
        color: Colors.foreground
        radius: 2
      }
    }

    handle: Rectangle {
      x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
      y: slider.topPadding + slider.availableHeight / 2 - height / 2
      implicitWidth: 12
      implicitHeight: 12
      radius: 6
      color: Colors.foreground
    }
  }

  Rectangle {
    id: outputBar

    visible: root.showOutput
    Layout.fillWidth: true
    implicitHeight: root.showOutput ? 6 : 0
    color: Colors.lighter_background

    Rectangle {
      readonly property real normalizedOutput: Math.max(0.0, Math.min(1.0, root.outputValue))

      width: parent.width * normalizedOutput
      height: parent.height
      color: Colors.foreground
    }
  }
}
