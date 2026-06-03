import QtQuick
import Quickshell

// ─── Launcher window ─────────────────────────────────────────────────────────
FloatingWindow {
    id: launcher

    required property var shell

    property alias menuInputItem: menu.inputItem
    property alias menuListItem: menu.listItem

    screen: shell.launcherScreen
    visible: shell.menuOpen
    title: "shell-launcher"
    implicitWidth: 600
    implicitHeight: 460
    color: shell.bg

    // ─── MenuSearch item data ──────────────────────────────────────────────────────
    // Set dynamicApps: true to populate Apps from all installed desktop entries
    // instead of the curated list below.
    readonly property bool dynamicApps: false

    readonly property var dynamicAppItems: {
        DesktopEntries.applicationsChanged;
        return DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
                    name: e.name,
                    iconPath: e.icon ? Quickshell.iconPath(e.icon) : "",
                    desktop: e.id
                })).sort((a, b) => a.name.localeCompare(b.name));
    }

    readonly property var curatedAppItems: [
        {
            name: "Firefox",
            icon: "󰈹",
            command: "firefox"
        },
        {
            name: "Files",
            icon: "󰉋",
            command: "nautilus"
        },
        {
            name: "LocalSend",
            icon: "󰒍",
            command: "localsend_app"
        },
        {
            name: "Windows",
            icon: "",
            command: "windows-vm"
        },
        {
            name: "Code",
            icon: "󰨞",
            command: "code"
        },
        {
            name: "1Password",
            icon: "󰌾",
            command: "1password"
        },
        {
            name: "Docker",
            icon: "",
            terminal: {
                klass: "lazy-docker",
                title: "lazy-docker",
                cmd: "lazydocker"
            }
        },
    ]

    readonly property var appItems: curatedAppItems

    readonly property var menuItems: [
        {
            name: "Apps",
            icon: "󰀻",
            items: dynamicApps ? dynamicAppItems : appItems
        },
        {
            name: "Install",
            icon: "󰇚",
            items: [
                {
                    name: "Windows",
                    icon: "",
                    command: "windows-install"
                },
            ]
        },
        {
            name: "Remove",
            icon: "󰆴",
            items: [
                {
                    name: "Windows",
                    icon: "",
                    command: "windows-uninstall",
                    confirm: true
                },
            ]
        },
        {
            name: "System",
            icon: "󰒓",
            items: [
                {
                    name: "Wallpaper",
                    icon: "󰸉",
                    command: "qs ipc call wallpaper open"
                },
                {
                    name: "Theme",
                    icon: "󰏘",
                    command: "qs ipc call theme open"
                },
                {
                    name: "Wi-Fi",
                    icon: "󰖩",
                    terminal: {
                        klass: "wifi-manager",
                        title: "wifi-manager",
                        cmd: "impala"
                    }
                },
                {
                    name: "Bluetooth",
                    icon: "󰂯",
                    terminal: {
                        klass: "bluetooth-manager",
                        title: "bluetooth-manager",
                        cmd: "bluetui"
                    }
                },
                {
                    name: "Audio",
                    icon: "󰕾",
                    terminal: {
                        klass: "audio-manager",
                        title: "audio-manager",
                        cmd: "wiremix"
                    }
                },
                {
                    name: "Status",
                    icon: "",
                    terminal: {
                        klass: "performance-monitor",
                        title: "performance-monitor",
                        cmd: "btop"
                    }
                },
            ]
        },
        {
            name: "NixOS",
            icon: "",
            items: [
                {
                    name: "Build",
                    icon: "󰔷",
                    terminal: {
                        klass: "nixos-build",
                        title: "nixos-build",
                        cmd: "nos-build"
                    }
                },
                {
                    name: "Update",
                    icon: "",
                    terminal: {
                        klass: "nixos-update",
                        title: "nixos-update",
                        cmd: "nos-update"
                    }
                },
                {
                    name: "Sync",
                    icon: "󰑐",
                    terminal: {
                        klass: "nixos-refresh",
                        title: "nixos-refresh",
                        cmd: "nos-refresh"
                    }
                },
                {
                    name: "Check",
                    icon: "",
                    terminal: {
                        klass: "nixos-check",
                        title: "nixos-check",
                        cmd: "nos-check",
                        pause: true
                    }
                },
            ]
        },
        {
            name: "Power",
            icon: "󰐥",
            items: [
                {
                    name: "Lock",
                    icon: "󰌾",
                    command: "hyprlock"
                },
                {
                    name: "Logout",
                    icon: "󰍃",
                    // Let Hyprland exit normally; UWSM will then tear down the
                    // graphical session cleanly. `uwsm stop` force-stops the
                    // compositor unit from inside the session and can leave
                    // user/app units in a bad state for relaunches.
                    command: "hl.dsp.exit()",
                    confirm: true
                },
                {
                    name: "Suspend",
                    icon: "󰒲",
                    command: "systemctl suspend",
                    confirm: true
                },
                {
                    name: "Reboot",
                    icon: "󰜉",
                    command: "systemctl reboot",
                    confirm: true
                },
                {
                    name: "Shutdown",
                    icon: "󰐥",
                    command: "systemctl poweroff",
                    confirm: true
                },
            ]
        },
        {
            name: "Profile",
            icon: "󰁹",
            items: [
                {
                    name: "Performance",
                    icon: "󱐋",
                    command: "powerprofilesctl set performance"
                },
                {
                    name: "Balance",
                    icon: "󰾅",
                    command: "powerprofilesctl set balanced"
                },
                {
                    name: "Power Saver",
                    icon: "󰌪",
                    command: "powerprofilesctl set power-saver"
                },
            ]
        },
    ]

    MenuSearch {
        id: menu
        anchors.fill: parent
        shell: launcher.shell
        query: launcher.shell.menuQuery
        items: launcher.shell.filteredMenuItems
        searchIcon: "󰍉"
        focusWhenVisible: launcher.shell.menuOpen
        confirmVisible: launcher.shell.confirmItem !== null
        confirmSelection: launcher.shell.confirmSelection
        confirmText: launcher.shell.confirmItem ? launcher.shell.confirmItem.name : "Confirm"

        itemText: function (item) {
            return item.name || "";
        }
        itemIcon: function (item) {
            return item.icon || "";
        }
        itemIconPath: function (item) {
            if (item.icon)
                return "";
            if (item.iconPath)
                return item.iconPath;
            if (item.desktop) {
                const entry = DesktopEntries.byId(item.desktop) || (!String(item.desktop).endsWith(".desktop") ? DesktopEntries.byId(item.desktop + ".desktop") : null);
                return entry && entry.icon ? Quickshell.iconPath(entry.icon) : "";
            }
            return "";
        }
        highlightedText: function (text) {
            return launcher.shell.highlightedText(text);
        }
        italicPredicate: function (item) {
            return launcher.shell.isCurrentPerformanceItem(item);
        }

        onQueryEdited: query => launcher.shell.menuQuery = query
        onAccepted: item => launcher.shell.enterMenuItem(item)
        onBack: launcher.shell.menuBack()
        onClearRequested: launcher.shell.menuQuery = ""
        onConfirmSelectionEdited: selection => launcher.shell.confirmSelection = selection
        onConfirmAccepted: launcher.shell.runConfirm()
        onConfirmCancelled: launcher.shell.cancelConfirm()
    }
}
