import QtQuick
import Quickshell
import Quickshell.Io

// ─── Process manager window ─────────────────────────────────────────────────
// Shows running graphical apps plus known background apps. Data comes from two
// sources:
//   1. `hyprctl clients -j` for visible windows, titles, focus addresses.
//   2. `/proc` + `ps` for CPU/RAM and background processes.
//
// Display rules:
//   - A single window for an app shows the app name.
//   - Multiple windows for the same app show each window title.
//   - Background-only apps show the app name.
//   - RAM/CPU are aggregated per desktop app, then split across multiple
//     windows so totals remain meaningful.
FloatingWindow {
    id: processManager

    required property var shell

    // ─── UI state ────────────────────────────────────────────────────────────
    property string query: ""
    property var processItems: []
    property bool showExtraProcesses: false
    property var confirmItem: null
    property string confirmSelection: "confirm"

    // ─── CPU sampling state ──────────────────────────────────────────────────
    // CPU usage is calculated from tick deltas between refreshes. This matches
    // tools like btop better than `ps %CPU`, which is lifetime-averaged.
    property var previousProcessTicks: ({})
    property real previousTotalTicks: 0
    property int cpuCount: 1

    readonly property int titleMaxLength: 48
    readonly property string dataMarker: "\n---QS-PS---\n"

    readonly property var filteredItems: filteredProcessItems()
    readonly property real listedCpu: processItems.reduce((sum, item) => sum + (Number(item.cpu) || 0), 0)
    readonly property real listedMem: processItems.reduce((sum, item) => sum + (Number(item.mem) || 0), 0)
    readonly property real totalCpu: parseUsageNumber(shell.cpuText, listedCpu)
    readonly property real totalMem: parseUsageNumber(shell.ramText, listedMem)

    screen: shell.processScreen
    visible: shell.processOpen
    title: "process-manager"
    implicitWidth: 700
    implicitHeight: 710
    color: shell.base

    // ─── Filtering / text formatting ─────────────────────────────────────────

    function parseUsageNumber(text, fallback) {
        const match = String(text || "").match(/([0-9]+(?:\.[0-9]+)?)/);
        return match ? Number(match[1]) : fallback;
    }

    function filteredProcessItems() {
        const q = query.trim().toLowerCase();
        if (q === "")
            return processItems;
        return processItems.filter(item => item.name.toLowerCase().includes(q));
    }

    function highlightedProcessText(text) {
        const value = String(text);
        const q = query.trim();
        if (q === "")
            return shell.escapeHtml(value);

        const start = value.toLowerCase().indexOf(q.toLowerCase());
        if (start < 0)
            return shell.escapeHtml(value);

        return shell.escapeHtml(value.slice(0, start)) + "<span style=\"color: " + shell.accent + "\">" + shell.escapeHtml(value.slice(start, start + q.length)) + "</span>" + shell.escapeHtml(value.slice(start + q.length));
    }

    function truncateTitle(title) {
        const value = String(title || "");
        return value.length > titleMaxLength ? value.slice(0, titleMaxLength - 3) + "..." : value;
    }

    function comparableName(name) {
        return String(name || "").toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    // ─── Desktop-entry lookup ────────────────────────────────────────────────
    // Desktop entries give us friendly app names and launcher-style icons.

    function desktopEntryForClass(appClass) {
        const normalized = String(appClass || "").toLowerCase();
        if (normalized === "")
            return null;

        const direct = DesktopEntries.byId(normalized + ".desktop") || DesktopEntries.byId(normalized);
        if (direct)
            return direct;

        for (const entry of DesktopEntries.applications.values) {
            const id = String(entry.id || "").replace(/\.desktop$/, "").toLowerCase();
            const leaf = id.split(".").pop();
            const name = String(entry.name || "").toLowerCase();

            if (id === normalized || leaf === normalized || name === normalized)
                return entry;
        }

        return null;
    }

    function desktopEntryForProcess(command, args) {
        const comm = String(command || "").toLowerCase();
        const line = String(args || "").toLowerCase();

        // Generic Electron processes need argv matching; otherwise they would
        // resolve to Electron instead of Teams, 1Password, etc.
        if (comm !== "electron") {
            const direct = desktopEntryForClass(comm);
            if (direct)
                return direct;
        }

        let best = null;
        let bestScore = 0;

        for (const entry of DesktopEntries.applications.values) {
            const id = String(entry.id || "").replace(/\.desktop$/, "").toLowerCase();
            if (id === "" || id === "electron")
                continue;

            const leaf = id.split(".").pop();
            const name = String(entry.name || "").toLowerCase();
            let score = 0;

            if (line.includes("/" + id + "/") || line.includes("/" + id + "-") || line.includes(".config/" + id))
                score = 100;
            else if (line.includes("/" + leaf + "/") || line.includes("/" + leaf + "-") || line.includes(".config/" + leaf))
                score = 90;
            else if (comm === leaf || comm === id)
                score = 80;
            else if (name !== "" && line.includes(name))
                score = 40;

            if (score > bestScore) {
                best = entry;
                bestScore = score;
            }
        }

        return best;
    }

    // ─── Item construction ───────────────────────────────────────────────────

    function createOrUpdateItem(itemsByKey, options) {
        const entry = options.entry;
        const fallbackName = options.fallbackName || "Unknown";
        const desktopId = entry ? String(entry.id || fallbackName) : fallbackName;
        const key = options.key || desktopId || String(options.pid);
        const cpu = Number(options.cpu) || 0;
        const memGiB = (Number(options.rssKiB) || 0) / 1048576;

        if (itemsByKey[key]) {
            itemsByKey[key].cpu += cpu;
            itemsByKey[key].mem += memGiB;
            if (options.address) {
                itemsByKey[key].address = options.address;
                itemsByKey[key].hasWindow = true;
            }
            return;
        }

        const iconPath = options.iconPath || (entry && entry.icon ? Quickshell.iconPath(entry.icon) : "");
        itemsByKey[key] = {
            pid: String(options.pid),
            itemKey: key,
            desktopId: desktopId,
            name: options.name || (entry ? entry.name : fallbackName),
            icon: iconPath ? "" : (options.fallbackIcon),
            iconPath: iconPath,
            cpu: cpu,
            mem: memGiB,
            address: options.address || "",
            hasWindow: !!options.address,
            terminateCommand: options.terminateCommand || ""
        };
    }

    function addClientWindowItems(itemsByKey, clients, visibleAppIds, visibleWindowTitles) {
        const clientInfos = [];
        const windowCounts = ({});

        // First pass: count windows per app so we know whether to use app name
        // or per-window title.
        for (const client of clients) {
            const pid = String(client.pid || "");
            const appClass = String(client.class || client.initialClass || "");
            if (pid === "" || appClass === "" || appClass === "org.quickshell")
                continue;

            const entry = desktopEntryForClass(appClass);
            const appId = entry ? String(entry.id || appClass) : appClass;
            const appName = entry ? entry.name : appClass;
            const info = {
                pid: pid,
                entry: entry,
                appId: appId,
                appName: appName,
                address: String(client.address || ""),
                title: String(client.title || "")
            };

            visibleAppIds[appId] = true;
            if (info.title)
                visibleWindowTitles[comparableName(info.title)] = true;
            windowCounts[appId] = (windowCounts[appId] || 0) + 1;
            clientInfos.push(info);
        }

        // Second pass: create one item per app, or one per window when an app
        // has multiple windows.
        for (const client of clientInfos) {
            const multipleWindows = windowCounts[client.appId] > 1;
            createOrUpdateItem(itemsByKey, {
                pid: client.pid,
                entry: client.entry,
                fallbackName: client.appName,
                fallbackIcon: "{}",
                address: client.address,
                key: multipleWindows ? "window:" + client.address : client.appId,
                name: multipleWindows ? truncateTitle(client.title || client.appName) : client.appName
            });
        }
    }

    function accumulateAppStats(appStats, appId, cpu, rssKiB) {
        if (!appStats[appId])
            appStats[appId] = {
                cpu: 0,
                rssKiB: 0
            };

        appStats[appId].cpu += Number(cpu) || 0;
        appStats[appId].rssKiB += Number(rssKiB) || 0;
    }

    function addStatsToVisibleItem(itemsByKey, name, cpu, rssKiB, terminateCommand, entry) {
        const target = comparableName(name);
        if (!target)
            return false;

        for (const key of Object.keys(itemsByKey)) {
            const item = itemsByKey[key];
            if (comparableName(item.name) === target) {
                item.cpu += Number(cpu) || 0;
                item.mem += (Number(rssKiB) || 0) / 1048576;

                // If this visible row is actually a terminal wrapper for a known
                // app, prefer the app's desktop-entry name/icon over the generic
                // terminal/window icon.
                if (entry) {
                    const iconPath = entry.icon ? Quickshell.iconPath(entry.icon) : "";
                    item.desktopId = String(entry.id || item.desktopId);
                    item.name = entry.name || item.name;
                    item.iconPath = iconPath || item.iconPath;
                    item.icon = iconPath ? "" : item.icon;
                }

                if (terminateCommand)
                    item.terminateCommand = terminateCommand;
                return true;
            }
        }

        return false;
    }

    function isManageableBackgroundProcess(command, args, rssKiB) {
        const comm = String(command || "");
        const line = String(args || "");
        const rss = Number(rssKiB) || 0;

        // Hide short-lived commands used by this picker and common shell glue.
        if (line.includes("qs-process-manager-list"))
            return false;
        if (["bash", "sh", "zsh", "fish", "ps", "python", "python3", "awk", "sed", "grep", "rg", "head", "tail", "cat"].includes(comm))
            return false;

        // Kernel threads and tiny helper processes add noise and are not useful
        // targets in a graphical process manager.
        if (line.startsWith("[") && line.endsWith("]"))
            return false;
        if (rss < 10240)
            return false;

        return true;
    }

    function displayNameForProcess(command) {
        const comm = String(command || "Unknown");
        if (comm === "quickshell" || comm === ".quickshell-wra")
            return "Quickshell";
        return comm;
    }

    function applyAggregatedStats(itemsByKey, appStats) {
        const itemCountsByApp = ({});
        for (const key of Object.keys(itemsByKey)) {
            const appId = itemsByKey[key].desktopId;
            itemCountsByApp[appId] = (itemCountsByApp[appId] || 0) + 1;
        }

        for (const key of Object.keys(itemsByKey)) {
            const item = itemsByKey[key];
            const stats = appStats[item.desktopId];
            if (!stats)
                continue;

            // Split aggregated app totals across multiple visible windows. This
            // avoids counting Firefox/Code/etc. totals once per window.
            const divisor = Math.max(1, itemCountsByApp[item.desktopId] || 1);
            item.cpu = stats.cpu / divisor;
            item.mem = (stats.rssKiB / 1048576) / divisor;
        }
    }

    function cpuPercentForProcess(pid, ticks, totalTicks) {
        if (previousTotalTicks <= 0 || totalTicks <= previousTotalTicks || previousProcessTicks[pid] === undefined)
            return 0;

        // Normalize against total CPU ticks across all cores so values are in
        // whole-system percent (0–100), matching the status bar expectation.
        return Math.max(0, ((ticks - previousProcessTicks[pid]) / (totalTicks - previousTotalTicks)) * 100);
    }

    // ─── Parsing / refresh pipeline ──────────────────────────────────────────

    function parseProcessData(text) {
        const raw = String(text);
        const markerIndex = raw.indexOf(dataMarker);
        const clientsText = markerIndex >= 0 ? raw.slice(0, markerIndex) : "[]";
        const psText = markerIndex >= 0 ? raw.slice(markerIndex + dataMarker.length) : raw;

        let clients = [];
        try {
            clients = JSON.parse(clientsText);
        } catch (e) {
            clients = [];
        }

        const itemsByKey = ({});
        const visibleAppIds = ({});
        const visibleWindowTitles = ({});
        const appStats = ({});
        const currentProcessTicks = ({});
        let totalTicks = 0;

        addClientWindowItems(itemsByKey, clients, visibleAppIds, visibleWindowTitles);

        for (const line of psText.split("\n")) {
            const trimmed = line.trim();
            if (trimmed === "")
                continue;

            const cpuCountMatch = trimmed.match(/^CPUS\s+(\d+)$/);
            if (cpuCountMatch) {
                cpuCount = Math.max(1, Number(cpuCountMatch[1]) || 1);
                continue;
            }

            const totalMatch = trimmed.match(/^TOTAL\s+(\d+)$/);
            if (totalMatch) {
                totalTicks = Number(totalMatch[1]) || 0;
                continue;
            }

            const dockerMatch = trimmed.match(/^DOCKER\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)$/);
            if (dockerMatch) {
                const id = dockerMatch[1];
                const cpu = Math.min(100, (Number(dockerMatch[2]) || 0) / Math.max(1, cpuCount));
                const rssKiB = Number(dockerMatch[3]) || 0;
                const name = dockerMatch[4];
                const stopCommand = "docker stop " + shell.shellQuote(id);

                // Containers are distinct managed targets from any GUI client
                // that may connect to them, e.g. Windows RDP session + Windows
                // Docker VM container. Always show the container as its own row.
                createOrUpdateItem(itemsByKey, {
                    pid: id,
                    fallbackName: name,
                    fallbackIcon: "",
                    iconPath: Quickshell.iconPath("docker"),
                    cpu: cpu,
                    rssKiB: rssKiB,
                    key: "docker:" + id,
                    terminateCommand: stopCommand
                });
                continue;
            }

            // Process rows: pid ticks rssKiB command args...
            const match = trimmed.match(/^(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s*(.*)$/);
            if (!match)
                continue;

            const pid = match[1];
            const ticks = Number(match[2]) || 0;
            const rssKiB = match[3];
            const command = match[4];
            const args = match[5] || command;
            if (args.includes("qs-process-manager-list"))
                continue;

            currentProcessTicks[pid] = ticks;

            const cpu = cpuPercentForProcess(pid, ticks, totalTicks);
            const entry = desktopEntryForProcess(command, args);

            if (entry) {
                const appId = String(entry.id || "");
                accumulateAppStats(appStats, appId, cpu, rssKiB);

                // If a terminal/window title already represents this process,
                // merge the stats into that visible row instead of adding a
                // second desktop-entry row. Example: `lazy-docker` window title
                // and `LazyDocker` desktop/process match.
                if (addStatsToVisibleItem(itemsByKey, entry.name, cpu, rssKiB, "", entry) || addStatsToVisibleItem(itemsByKey, command, cpu, rssKiB, "", entry))
                    continue;

                // If the app has no visible windows, add a background-only row.
                if (!visibleAppIds[appId]) {
                    createOrUpdateItem(itemsByKey, {
                        pid: pid,
                        entry: entry,
                        fallbackName: entry.name,
                        fallbackIcon: "{}",
                        cpu: cpu,
                        rssKiB: rssKiB
                    });
                }
            } else if (showExtraProcesses && isManageableBackgroundProcess(command, args, rssKiB)) {
                const displayName = displayNameForProcess(command);

                // If a terminal window is already representing this foreground
                // TUI command by title, do not add the child process as a second
                // row. Example: kitty title `lazy-docker` + process `lazydocker`.
                if (visibleWindowTitles[comparableName(displayName)] || visibleWindowTitles[comparableName(command)])
                    continue;

                // Optional non-desktop user services/background apps, e.g.
                // Quickshell. Hidden by default to keep the list app-focused;
                // press `.` to toggle them.
                createOrUpdateItem(itemsByKey, {
                    pid: pid,
                    fallbackName: displayName,
                    fallbackIcon: "{}",
                    cpu: cpu,
                    rssKiB: rssKiB,
                    key: "process:" + command
                });
            }
        }

        if (totalTicks > 0) {
            previousProcessTicks = currentProcessTicks;
            previousTotalTicks = totalTicks;
        }

        applyAggregatedStats(itemsByKey, appStats);
        commitItems(itemsByKey);
    }

    function commitItems(itemsByKey) {
        const list = picker.listItem;
        const currentContentY = list.contentY;
        const viewportGeneration = picker.viewportGeneration;

        // If the selected row is off-screen, ListView may auto-scroll back to it
        // when the model is replaced. Anchor selection to the visible viewport
        // first so refreshes never pull the scroll position back to an old item.
        // MenuSearch rows are fixed at 54px, so calculating the visible range is
        // more reliable than indexAt(), which can return -1 during model churn.
        const rowHeight = 54;
        const topIndex = Math.max(0, Math.floor(currentContentY / rowHeight));
        const bottomIndex = Math.max(topIndex, Math.floor((currentContentY + list.height - 1) / rowHeight));
        const anchoredIndex = (list.currentIndex < topIndex || list.currentIndex > bottomIndex) ? topIndex : list.currentIndex;

        const newItems = Object.values(itemsByKey).map(item => Object.assign(item, {
                cpuText: item.cpu.toFixed(1) + "%",
                memText: item.mem.toFixed(1) + "G"
            })).sort((a, b) => (b.mem - a.mem) || (b.cpu - a.cpu) || a.name.localeCompare(b.name));

        const nextIndex = Math.max(0, Math.min(anchoredIndex, newItems.length - 1));

        // Keep both cursor index and viewport fixed during refreshes. We restore
        // by index, not by process key, so sorting by live CPU/RAM cannot drag
        // the cursor back to an old process.
        processItems = newItems;
        list.currentIndex = nextIndex;
        list.contentY = currentContentY;
        Qt.callLater(function () {
            // If the user navigated after this refresh started, do not restore a
            // stale viewport. That stale restore was the source of the edge
            // jitter while arrow-key scrolling through the process list.
            if (picker.viewportGeneration !== viewportGeneration)
                return;

            list.currentIndex = nextIndex;
            list.contentY = currentContentY;
        });
    }

    function refresh() {
        // The sampler can take longer than the 500ms UI refresh interval when
        // Docker is queried. Do not kill an in-flight sample, otherwise slow
        // container stats may never make it into the list.
        if (listProcess.running)
            return;

        listProcess.command = ["bash", "-c", "hyprctl clients -j 2>/dev/null; printf '\n---QS-PS---\n'; exec -a qs-process-manager-list python3 - <<'PY'\nimport os, re, subprocess\nprint('CPUS', os.cpu_count() or 1)\ntry:\n    with open('/proc/stat') as f:\n        parts = f.readline().split()[1:]\n    print('TOTAL', sum(int(p) for p in parts))\nexcept Exception:\n    print('TOTAL', 0)\ntry:\n    rows = subprocess.check_output(['ps', '-eo', 'pid=,rss=,comm=,args='], text=True)\nexcept Exception:\n    rows = ''\ncurrent_uid = os.getuid()\nfor line in rows.splitlines():\n    fields = line.strip().split(None, 3)\n    if len(fields) < 3:\n        continue\n    pid, rss, comm = fields[:3]\n    args = fields[3] if len(fields) > 3 else comm\n    try:\n        if os.stat('/proc/%s' % pid).st_uid != current_uid:\n            continue\n        stat = open('/proc/%s/stat' % pid).read()\n        rest = stat.rsplit(') ', 1)[1].split()\n        ticks = int(rest[11]) + int(rest[12])\n        mem = rss\n        try:\n            with open('/proc/%s/smaps_rollup' % pid) as sf:\n                for sl in sf:\n                    if sl.startswith('Pss:'):\n                        pss = sl.split()[1]\n                        if pss and int(pss) > 0:\n                            mem = pss\n                        break\n        except Exception:\n            pass\n        if '--type=' in args and '--application-name=' not in args:\n            try:\n                ppid = rest[1]\n                ac = open('/proc/%s/cmdline' % ppid).read().replace(chr(0), ' ')\n                if '--application-name=' not in ac:\n                    gppid = open('/proc/%s/stat' % ppid).read().rsplit(') ', 1)[1].split()[1]\n                    ac = open('/proc/%s/cmdline' % gppid).read().replace(chr(0), ' ')\n                if '--application-name=' in ac:\n                    appname = ac.split('--application-name=')[1].split()[0]\n                    args = args + ' --application-name=' + appname\n            except Exception:\n                pass\n    except Exception:\n        continue\n    print(pid, ticks, mem, comm, args)\n\ndef mem_to_kib(value):\n    # Docker uses compact IEC units such as `620MiB`, `2.4GiB`, or sometimes\n    # spaced forms. Convert the *used* side of `.MemUsage` to KiB for QML.\n    match = re.search(r'([0-9]+(?:\\.[0-9]+)?)\\s*([KMGT]?i?B|[KMGT]?B)?', value.strip(), re.I)\n    if not match:\n        return 0\n\n    number = float(match.group(1))\n    unit = (match.group(2) or 'B').lower()\n\n    if unit.startswith('k'):\n        return int(number)\n    if unit.startswith('m'):\n        return int(number * 1024)\n    if unit.startswith('g'):\n        return int(number * 1024 * 1024)\n    if unit.startswith('t'):\n        return int(number * 1024 * 1024 * 1024)\n    return int(number / 1024)\n\ntry:\n    stats = subprocess.check_output(['docker', 'stats', '--no-stream', '--format', '{{.ID}}\\t{{.Name}}\\t{{.CPUPerc}}\\t{{.MemUsage}}'], text=True, stderr=subprocess.DEVNULL, timeout=2)\nexcept Exception:\n    stats = ''\nfor line in stats.splitlines():\n    fields = line.split('\\t')\n    if len(fields) < 4:\n        continue\n    cid, name, cpu_text, mem_text = fields[:4]\n    cpu = cpu_text.strip().rstrip('%') or '0'\n    used_mem = mem_text.split('/')[0].strip()\n    print('DOCKER', cid, cpu, mem_to_kib(used_mem), name)\nPY"];
        listProcess.running = true;
    }

    // ─── Actions ─────────────────────────────────────────────────────────────

    function requestTerminate(item) {
        if (!item)
            return;
        confirmItem = item;
        confirmSelection = "confirm";
    }

    function cancelConfirm() {
        confirmItem = null;
        confirmSelection = "confirm";
        picker.inputItem.forceActiveFocus();
    }

    function terminateConfirmed() {
        if (!confirmItem)
            return;

        killProcess.running = false;
        killProcess.command = confirmItem.terminateCommand ? ["bash", "-c", confirmItem.terminateCommand] : ["bash", "-c", "kill -- " + shell.shellQuote(confirmItem.pid) + " 2>/dev/null || true"];
        killProcess.running = true;
        confirmItem = null;
        confirmSelection = "confirm";
    }

    // ─── External processes / timers ─────────────────────────────────────────

    Process {
        id: listProcess
        stdout: StdioCollector {
            onStreamFinished: processManager.parseProcessData(this.text)
        }
    }

    Process {
        id: killProcess
        onRunningChanged: if (!running)
            refreshDelay.restart()
    }

    Timer {
        id: refreshDelay
        interval: 250
        onTriggered: processManager.refresh()
    }

    Timer {
        interval: 2000
        running: processManager.visible && processManager.confirmItem === null
        repeat: true
        onTriggered: processManager.refresh()
    }

    // ─── UI ──────────────────────────────────────────────────────────────────

    MenuSearch {
        id: picker
        anchors.fill: parent
        radius: 12
        shell: processManager.shell
        query: processManager.query
        items: processManager.filteredItems
        searchIcon: "󰍉"
        placeholderText: "Search apps"
        headerCommandText: "  " + processManager.totalCpu.toFixed(1) + "%"
        headerCategoryText: "  " + processManager.totalMem.toFixed(1) + "G"
        focusWhenVisible: processManager.shell.processOpen
        terminateKeyEnabled: true
        resetIndexOnItemsChanged: false
        hoverSelectEnabled: false
        confirmVisible: processManager.confirmItem !== null
        confirmSelection: processManager.confirmSelection
        confirmText: "Terminate"
        confirmTitle: processManager.confirmItem ? "Terminate " + processManager.confirmItem.name + "?" : "Terminate?"

        itemText: function (item) {
            return item.name;
        }
        itemIcon: function (item) {
            return item.icon || "";
        }
        itemIconPath: function (item) {
            return item.iconPath || "";
        }
        itemCommand: function (item) {
            return "  " + item.cpuText;
        }
        itemCategory: function (item) {
            return "  " + item.memText;
        }
        highlightedText: function (text) {
            return processManager.highlightedProcessText(text);
        }

        // Enter/click intentionally does nothing. Termination is explicitly
        // bound to `t` so accidental Enter cannot kill or launch anything.
        onAccepted: item => {}
        onTerminateRequested: item => processManager.requestTerminate(item)
        onDotPressed: {
            processManager.showExtraProcesses = !processManager.showExtraProcesses;
            processManager.refresh();
        }
        onQueryEdited: query => processManager.query = query
        onClearRequested: processManager.query = ""
        onConfirmSelectionEdited: selection => processManager.confirmSelection = selection
        onConfirmAccepted: processManager.terminateConfirmed()
        onConfirmCancelled: processManager.cancelConfirm()
        onBack: {
            if (processManager.confirmItem)
                processManager.cancelConfirm();
            else
                processManager.shell.processOpen = false;
        }
    }

    // If another shell window stole focus, restore it when this surface is
    // reopened/toggled so Escape continues to work reliably.
    Connections {
        target: processManager.shell

        function onProcessOpenChanged() {
            if (processManager.shell.processOpen)
                picker.inputItem.forceActiveFocus();
        }
    }

    onVisibleChanged: {
        if (visible) {
            query = "";
            confirmItem = null;
            confirmSelection = "confirm";
            refresh();
            picker.inputItem.forceActiveFocus();
        }
    }

    onClosed: processManager.shell.processOpen = false
}
