import QtQuick
import Quickshell
import Quickshell.Io

// ─── Screen-share picker window ──────────────────────────────────────────────
// Opened by screenshare.sh via IPC. Reads a list of monitors from a temp file,
// displays previews, and writes the user's selection back to a result file.
// The script polls that file and forwards the value to the portal.
FloatingWindow {
    id: picker

    required property var shell

    // Set by openPicker(); the script polls result for the user's choice.
    property string resultPath: ""
    property string sourcePath: ""
    property var screenItems: []
    // Prevents cancel() from firing while the picker is being re-opened.
    property bool suppressCloseCancel: false

    // ─── Layout dimensions ───────────────────────────────────────────────────
    readonly property int previewWidth: 390
    readonly property int previewHeight: 230
    readonly property int previewGap: 10
    readonly property int outerMargin: 10
    readonly property int tabsHeight: 34
    readonly property int minDialogWidth: 430

    // Grid scales up to 3 columns based on the number of monitors.
    readonly property int activeItemCount: screenItems.length
    readonly property int screenColumns: Math.max(1, Math.min(3, activeItemCount))
    readonly property int screenRows: Math.max(1, Math.ceil(activeItemCount / 3))

    visible: shell.screenShareOpen
    title: "screen-share-picker"
    implicitWidth: Math.max(minDialogWidth, outerMargin * 2 + previewWidth * screenColumns + previewGap * Math.max(screenColumns - 1, 0))
    implicitHeight: outerMargin * 2 + tabsHeight + previewGap + previewHeight * screenRows + previewGap * Math.max(screenRows - 1, 0)
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: Qt.size(implicitWidth, implicitHeight)
    color: shell.bg

    // ─── IPC entry point ─────────────────────────────────────────────────────
    // Called by the script after writing monitor info to sourcePath.
    function openPicker(result, source) {
        suppressCloseCancel = true;
        shell.screenShareOpen = false;
        resultPath = "";
        sourcePath = "";
        screenItems = [];

        Qt.callLater(function () {
            resultPath = result;
            sourcePath = source;
            suppressCloseCancel = false;
            loadProcess.running = false;
            loadProcess.command = ["cat", sourcePath];
            loadProcess.running = true;
        });
    }

    // Parse newline-separated "screen|value|label|previewPath" lines from the source file.
    function parseItems(text) {
        const items = [];
        for (const line of String(text).split("\n")) {
            if (line.trim() === "")
                continue;
            const parts = line.split("|");
            if (parts.length < 3 || parts[0] !== "screen")
                continue;
            items.push({
                value: parts[1],
                label: parts[2],
                preview: parts.length >= 4 ? parts.slice(3).join("|") : ""
            });
        }
        screenItems = items;
        shell.screenShareOpen = true;
    }

    // ─── Selection helpers ───────────────────────────────────────────────────
    // Each writes a result token then closes. The script reads the token.

    function writeResult(value) {
        selectionProcess.running = false;
        selectionProcess.command = ["bash", "-c", "printf '%s\\n' " + shell.shellQuote(value) + " > " + shell.shellQuote(resultPath)];
        selectionProcess.running = true;
    }

    function chooseScreen(item) {
        if (!item || !resultPath)
            return;
        writeResult("screen:" + item.value);
        shell.screenShareOpen = false;
    }

    function chooseRegion() {
        if (!resultPath)
            return;
        writeResult("region:any");
        shell.screenShareOpen = false;
    }

    function cancel() {
        if (resultPath)
            writeResult("cancel");
        shell.screenShareOpen = false;
    }

    // ─── Shell processes ─────────────────────────────────────────────────────
    Process {
        id: selectionProcess
    }

    Process {
        id: loadProcess
        stdout: StdioCollector {
            onStreamFinished: picker.parseItems(this.text)
        }
    }

    // ─── UI ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: pickerContent
        anchors.fill: parent
        color: picker.shell.bg
        focus: picker.shell.screenShareOpen
        Keys.onEscapePressed: picker.cancel()

        Column {
            anchors.fill: parent
            anchors.margins: picker.outerMargin
            spacing: picker.previewGap

            // ─── Tab row: Screen / Region ────────────────────────────────────────
            Row {
                width: parent.width
                height: picker.tabsHeight
                spacing: 8

                // "Screen" tab — always active (screen grid is shown by default)
                Rectangle {
                    width: 130
                    height: picker.tabsHeight
                    radius: 5
                    color: picker.shell.bgLight
                    border.color: picker.shell.primary
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "󰍹  Screen"
                        color: picker.shell.fg
                        font.family: picker.shell.monoFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }

                // "Region" tab — clicking launches slurp for freehand selection
                Rectangle {
                    width: 130
                    height: picker.tabsHeight
                    radius: 5
                    color: "transparent"
                    border.color: regionMouse.containsMouse ? picker.shell.primary : picker.shell.bgLight
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "󰩭  Region"
                        color: regionMouse.containsMouse ? picker.shell.fg : picker.shell.fgDark
                        font.family: picker.shell.monoFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: regionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: picker.chooseRegion()
                    }
                }
            }

            // ─── Monitor preview grid ────────────────────────────────────────────
            Grid {
                width: parent.width
                height: picker.previewHeight * picker.screenRows + picker.previewGap * Math.max(picker.screenRows - 1, 0)
                columns: picker.screenColumns
                rowSpacing: picker.previewGap
                columnSpacing: picker.previewGap

                Repeater {
                    model: picker.screenItems

                    Rectangle {
                        required property var modelData
                        width: picker.previewWidth
                        height: picker.previewHeight
                        radius: 6
                        color: mouse.containsMouse ? picker.shell.bgLight : picker.shell.bgLight
                        border.color: mouse.containsMouse ? picker.shell.primary : "transparent"
                        border.width: mouse.containsMouse ? 2 : 0

                        Image {
                            anchors.fill: parent
                            anchors.margins: 8
                            source: modelData.preview ? "file://" + modelData.preview : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: picker.chooseScreen(modelData)
                        }
                    }
                }
            }
        }
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────
    onVisibleChanged: if (visible)
        pickerContent.forceActiveFocus()

    onClosed: {
        if (!suppressCloseCancel && shell.screenShareOpen)
            cancel();
        shell.screenShareOpen = false;
    }
}
