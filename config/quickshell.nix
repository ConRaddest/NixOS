{ config, pkgs, colors, font, ... }:

let
  repo = "${config.home.homeDirectory}/OS/config";
in
{
  home.packages = [ pkgs.quickshell ];

  # shell.qml is generated so it can pull tokens from the shared `colors`/`font`
  # set in home.nix. The components/ directory stays as an out-of-store symlink
  # so QML edits don't need a rebuild.
  xdg.configFile."quickshell/shell.qml".text = ''
    //@ pragma ShellId shell

    import QtQuick
    import Quickshell
    import Quickshell.Io
    import Quickshell.Hyprland
    import "components"

    ShellRoot {
      id: root

      // ── Colours (matched to btop tokyo-night theme) ──────────────────── //
      readonly property string bg:            "${colors.bg}"
      readonly property string bgAlt:         "${colors.bgAlt}"
      readonly property string fg:            "${colors.fg}"
      readonly property string fgDim:         "${colors.comment}"
      readonly property string accent:        "${colors.blue}"
      readonly property string hover:         "${colors.hover}"
      readonly property string surfaceLight:  "${colors.surfaceLight}"
      readonly property string selection:     "${colors.selection}"

      readonly property string monoFont:      "${font.mono}"

      // ── Status bar state ─────────────────────────────────────────────── //
      property string cpuText:       "--"
      property string ramText:       "--"
      property string wifiText:      "󰖪"
      property string bluetoothText: "󰂲"
      property string batteryText:   "󰚥 AC"
      property string timeText:      Qt.formatDateTime(new Date(), "ddd dd MMM HH:mm:ss")

      // ── Launcher state ───────────────────────────────────────────────── //
      property bool   menuOpen:         false
      property string menuQuery:        ""
      property var    menuStack:        []
      property var    confirmItem:      null
      property string confirmSelection: "confirm"
      property bool   openedAsSubmenu:  false
      property string performanceProfile: ""

      readonly property var menuItems:          menuConfig.items
      readonly property var currentMenuItems:   menuStack.length > 0 ? menuStack[menuStack.length - 1].items : menuItems
      readonly property var searchableMenuItems: flattenMenu(currentMenuItems, "")
      readonly property var filteredMenuItems:  getFilteredMenuItems()

      MenuItems { id: menuConfig }

      // ── Menu helpers ─────────────────────────────────────────────────── //
      function flattenMenu(items, prefix) {
        let flattened = []
        for (const item of items) {
          const displayName = prefix ? prefix + " / " + item.name : item.name
          flattened.push(Object.assign({}, item, { displayName: displayName }))
          if (item.items)
            flattened = flattened.concat(flattenMenu(item.items, displayName))
        }
        return flattened
      }

      function escapeHtml(text) {
        return String(text)
          .replace(/&/g, "&amp;")
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;")
      }

      function getFilteredMenuItems() {
        const query = menuQuery.trim()
        if (query === "")
          return currentMenuItems

        const matches = searchableMenuItems.filter(item => item.name.toLowerCase().includes(query.toLowerCase()))
        const calculation = calculate(query)

        if (calculation !== null)
          return matches.concat([{ name: query + " = " + calculation, icon: "󰃬", result: calculation, calculator: true }])

        if (matches.length === 0)
          return [{ name: "Search: " + query, icon: "󰖟", query: query, googleSearch: true }]

        return matches
      }

      function calculate(expression) {
        let text = expression.replace(/\[/g, "(").replace(/\]/g, ")").replace(/×/g, "*").replace(/÷/g, "/")
        text = text.replace(/,/g, ".").replace(/\s+/g, "")
        if (text === "" || !/[0-9]/.test(text) || /[^0-9+\-*/^().]/.test(text))
          return null

        let index = 0
        function peek() { return text[index] }
        function consume(token) { if (text[index] === token) { index++; return true } return false }
        function parseNumber() {
          const start = index
          while (/[0-9.]/.test(peek() || "")) index++
          if (start === index) throw "number expected"
          const raw = text.slice(start, index)
          if ((raw.match(/\./g) || []).length > 1) throw "invalid number"
          return Number(raw)
        }
        function parsePrimary() {
          if (consume("+")) return parsePrimary()
          if (consume("-")) return -parsePrimary()
          if (consume("(")) { const value = parseAddSub(); if (!consume(")")) throw "missing )"; return value }
          return parseNumber()
        }
        function parsePower() { let value = parsePrimary(); if (consume("^")) value = Math.pow(value, parsePower()); return value }
        function parseMulDiv() {
          let value = parsePower()
          while (true) {
            if (consume("*")) value *= parsePower()
            else if (consume("/")) value /= parsePower()
            else return value
          }
        }
        function parseAddSub() {
          let value = parseMulDiv()
          while (true) {
            if (consume("+")) value += parseMulDiv()
            else if (consume("-")) value -= parseMulDiv()
            else return value
          }
        }
        try {
          const value = parseAddSub()
          if (index !== text.length || !isFinite(value)) return null
          return Number(value.toFixed(10)).toString()
        } catch (e) { return null }
      }

      function highlightedText(text) {
        const value = String(text)
        const query = menuQuery.trim()
        if (query === "") return escapeHtml(value)
        const lowerValue = value.toLowerCase()
        const lowerQuery = query.toLowerCase()
        let result = ""
        let position = 0
        let match = lowerValue.indexOf(lowerQuery, position)
        while (match !== -1) {
          result += escapeHtml(value.slice(position, match))
          result += "<span style=\"color: " + accent + "\">" + escapeHtml(value.slice(match, match + query.length)) + "</span>"
          position = match + query.length
          match = lowerValue.indexOf(lowerQuery, position)
        }
        return result + escapeHtml(value.slice(position))
      }

      function isCurrentPerformanceItem(item) {
        if (!item || !item.command) return false
        if (item.command === "powerprofilesctl set performance") return performanceProfile === "performance"
        if (item.command === "powerprofilesctl set balanced")    return performanceProfile === "balanced"
        if (item.command === "powerprofilesctl set power-saver") return performanceProfile === "power-saver"
        return false
      }

      function resetMenuView() {
        if (launcher.menuInputItem) launcher.menuInputItem.text = ""
        if (launcher.menuListItem)  launcher.menuListItem.currentIndex = 0
      }

      function focusMenuInput() {
        if (launcher.menuInputItem) launcher.menuInputItem.forceActiveFocus()
      }

      function resetMenu() {
        menuStack        = []
        confirmItem      = null
        confirmSelection = "confirm"
        menuQuery        = ""
        openedAsSubmenu  = false
        resetMenuView()
      }

      function closeMenu() {
        menuOpen = false
        resetMenu()
      }

      function confirmAction(item) {
        confirmItem      = item
        confirmSelection = "confirm"
      }

      function cancelConfirm() {
        confirmItem      = null
        confirmSelection = "confirm"
        focusMenuInput()
      }

      function runConfirm() {
        if (confirmItem && confirmItem.command) {
          runDetached(confirmItem.command)
          closeMenu()
        }
      }

      function runConfirmSelection() {
        if (confirmSelection === "confirm") runConfirm()
        else cancelConfirm()
      }

      function findMenuPath(items, targetName, pathStack) {
        for (let i = 0; i < items.length; i++) {
          const item = items[i]
          if (item.items) {
            const submenu = Object.assign({}, item, { parentIndex: i })
            if (item.name.toLowerCase() === targetName.toLowerCase()) {
              pathStack.push(submenu)
              return true
            }
            pathStack.push(submenu)
            if (findMenuPath(item.items, targetName, pathStack)) return true
            pathStack.pop()
          }
        }
        return false
      }

      function enterMenuItem(item) {
        if (item.googleSearch) {
          runDetached("firefox 'https://www.google.com/search?q=" + encodeURIComponent(item.query) + "'")
          closeMenu()
        } else if (item.calculator) {
          runDetached("printf %s '" + item.result + "' | wl-copy")
          closeMenu()
        } else if (item.items) {
          const parentIndex = launcher.menuListItem.currentIndex
          menuStack = menuStack.concat([Object.assign({}, item, { parentIndex: parentIndex })])
          menuQuery = ""
          resetMenuView()
        } else if (item.command) {
          if (item.confirm) confirmAction(item)
          else { runDetached(item.command); closeMenu() }
        }
      }

      function menuBack() {
        if (confirmItem) {
          cancelConfirm()
        } else if (openedAsSubmenu) {
          closeMenu()
        } else if (menuStack.length > 0) {
          const previousIndex = menuStack[menuStack.length - 1].parentIndex || 0
          menuStack = menuStack.slice(0, menuStack.length - 1)
          menuQuery = ""
          resetMenuView()
          launcher.menuListItem.currentIndex = previousIndex
        } else {
          closeMenu()
        }
      }

      onMenuOpenChanged: {
        if (menuOpen) {
          focusMenuInput()
          if (launcher.menuListItem) launcher.menuListItem.currentIndex = 0
        } else {
          resetMenu()
        }
      }

      // ── Utilities ────────────────────────────────────────────────────── //
      readonly property string terminal: "kitty"

      function launchTerminal(klass, title, cmd) {
        runDetached(terminal + " --class " + shellQuote(klass) + " --title " + shellQuote(title) + " -e " + cmd)
      }

      function runDetached(command) {
        launchProcess.command = ["bash", "-lc", "setsid bash -lc " + shellQuote(command) + " >/dev/null 2>&1 &"]
        launchProcess.running = true
      }

      function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\'''") + "'"
      }

      // ── Processes & timers ───────────────────────────────────────────── //
      Process { id: launchProcess }

      Process {
        id: statusProcess
        stdout: StdioCollector {
          onStreamFinished: {
            const parts = this.text.trim().split("|")
            if (parts.length >= 5) {
              root.cpuText       = parts[0]
              root.ramText       = parts[1]
              root.wifiText      = parts[2]
              root.bluetoothText = parts[3]
              root.batteryText   = parts[4]
            }
          }
        }
      }

      Process {
        id: profileProcess
        stdout: StdioCollector {
          onStreamFinished: root.performanceProfile = this.text.trim()
        }
      }

      Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
          root.timeText = Qt.formatDateTime(new Date(), "ddd dd MMM HH:mm:ss")

          statusProcess.running = false
          statusProcess.command = ["bash", "-c", "$HOME/.config/quickshell/scripts/status.sh"]
          statusProcess.running = true

          profileProcess.running = false
          profileProcess.command = ["bash", "-c", "command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl get || true"]
          profileProcess.running = true
        }
      }

      // ── IPC ──────────────────────────────────────────────────────────── //
      IpcHandler {
        target: "launcher"

        function open() {
          root.menuOpen = false
          root.menuOpen = true
        }

        function openSubmenu(targetName: string): void {
          root.closeMenu()
          if (targetName && targetName.trim() !== "") {
            let path = []
            if (root.findMenuPath(root.menuItems, targetName, path)) {
              root.menuStack = path
              root.openedAsSubmenu = true
            }
          }
          root.menuOpen = true
        }
      }

      // ── Windows ──────────────────────────────────────────────────────── //
      Variants {
        model: Quickshell.screens

        StatusBar {
          required property var modelData
          screen: modelData
          shell: root
        }
      }

      LauncherWindow {
        id: launcher
        shell: root
      }
    }
  '';

  xdg.configFile."quickshell/components" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repo}/quickshell/components";
    recursive = true;
  };

  xdg.configFile."quickshell/scripts" = {
    source = config.lib.file.mkOutOfStoreSymlink "${repo}/quickshell/scripts";
    recursive = true;
  };
}
