import QtQuick
import Quickshell
import Quickshell.Io

// ─── Screenshot history window ───────────────────────────────────────────────
FloatingWindow {
    id: screenshots

    required property var shell

    property string query: ""
    property var screenshotItems: []
    property string screenshotDir: String(shell.homeDir).replace(/^file:\/\//, "") + "/Screenshots"

    visible: shell.screenshotsOpen
    title: "screenshot-picker"
    implicitWidth: 760
    implicitHeight: 460
    color: shell.bg

    Process {
        id: copyProcess
    }

    Process {
        id: fetchProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.trim() !== "");
                screenshots.screenshotItems = lines.map(path => ({
                            path: path,
                            name: screenshots.fileName(path),
                            label: screenshots.screenshotLabel(screenshots.fileName(path)),
                            icon: "󰉏"
                        }));
            }
        }
    }

    function fileName(path) {
        const parts = String(path).split("/");
        return parts[parts.length - 1];
    }

    function displayPath(path) {
        const home = String(shell.homeDir).replace(/^file:\/\//, "");
        return String(path).replace(home, "~");
    }

    function screenshotLabel(name) {
        const match = String(name).match(/^screenshot-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.[^.]+$/);
        if (!match)
            return name;
        const date = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]), Number(match[4]), Number(match[5]), Number(match[6]));
        return Qt.formatDateTime(date, "ddd dd MMM HH:mm:ss");
    }

    function copyScreenshot(item) {
        if (!item || !item.path)
            return;
        copyProcess.command = ["bash", "-c", "wl-copy --type image/png < " + shell.shellQuote(item.path)];
        copyProcess.running = true;
        shell.screenshotsOpen = false;
    }

    function refresh() {
        fetchProcess.running = false;
        fetchProcess.command = ["bash", "-c", "find " + shell.shellQuote(screenshotDir) + " -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort -r"];
        fetchProcess.running = true;
    }

    ListPreviewPicker {
        id: picker
        anchors.fill: parent
        shell: screenshots.shell
        searchIcon: "󰍉"
        query: screenshots.query
        items: screenshots.screenshotItems
        itemText: function (item) {
            return item.label;
        }
        itemIcon: function (item) {
            return item.icon;
        }
        itemMatches: function (item, q) {
            return item.label.toLowerCase().includes(q) || item.name.toLowerCase().includes(q);
        }
        imageSource: function (item) {
            return item ? "file://" + item.path : "";
        }

        onQueryEdited: query => screenshots.query = query
        onAccepted: item => screenshots.copyScreenshot(item)
        onBack: screenshots.shell.screenshotsOpen = false
    }

    onVisibleChanged: {
        if (visible) {
            query = "";
            refresh();
            picker.inputItem.forceActiveFocus();
        }
    }

    onClosed: screenshots.shell.screenshotsOpen = false
}
