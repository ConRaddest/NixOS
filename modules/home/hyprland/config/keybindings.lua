local shell = require("nix.shell")
local monitors = require("config.monitors")

local function open_terminal(class, command, keep_open)
	local suffix = keep_open and "; exec fish" or ""
	local terminal = "uwsm app -- kitty --class "
		.. class
		.. " --title "
		.. class
		.. " -e bash -lic '"
		.. command
		.. suffix
		.. "'"
	return hl.dsp.exec_cmd(terminal)
end

local function send_shortcut_once(mods, key)
	return function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
		hl.timer(function()
			hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
		end, { timeout = 50, type = "oneshot" })
	end
end

local function active_window_is_terminal()
	local window = hl.get_active_window()
	if not window then
		return false
	end

	for _, tag in ipairs(window.tags or {}) do
		if tag:gsub("%*$", "") == "terminal" then
			return true
		end
	end

	return window.class == "kitty"
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
	local default_shortcut = send_shortcut_once(default_mods, default_key)
	local terminal_shortcut = send_shortcut_once(terminal_mods, terminal_key)

	return function()
		if active_window_is_terminal() then
			terminal_shortcut()
		else
			default_shortcut()
		end
	end
end

hl.bind("SUPER + Space", hl.dsp.exec_cmd(shell.launcher))
hl.bind("SUPER + P", hl.dsp.exec_cmd(shell.process_list))

hl.bind("XF86PowerOff", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })

hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("terminal"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- kitty --class yazi --title yazi -e yazi"))
hl.bind("SUPER + Return", hl.dsp.exec_cmd("uwsm app -- kitty"))
hl.bind("SUPER + W", hl.dsp.window.close())
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind("SUPER + A", function()
	hl.plugin.scrolloverview.overview("toggle")
end)

hl.bind("SUPER + mouse_up", function()
	monitors.scroll_workspace(1)
end)
hl.bind("SUPER + mouse_down", function()
	monitors.scroll_workspace(-1)
end)

for _, direction in ipairs({ "left", "right", "up", "down" }) do
	hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
	hl.bind("SUPER + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
end

for workspace = 1, 9 do
	hl.bind("SUPER + " .. workspace, hl.dsp.focus({ workspace = workspace }))
	hl.bind("SUPER + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind("SUPER + equal", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("hyprpicker"))

local screenshot_command = "mkdir -p ~/Screenshots && "
	.. 'file="$HOME/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png" && '
	.. 'grim -g "$(slurp)" "$file" && wl-copy --type image/png < "$file"'
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(screenshot_command))

hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("uwsm app -- nos-build"), { desc = "Build NixOS configuration" })
hl.bind("SUPER + SHIFT + U", hl.dsp.exec_cmd("uwsm app -- nos-update"), { desc = "Update NixOS configuration" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("uwsm app -- nos-refresh"), { desc = "Refresh Home Manager" })
hl.bind("SUPER + SHIFT + I", open_terminal("nos-install", "nos-install", true), { desc = "Install Nix package" })
hl.bind("SUPER + SHIFT + X", open_terminal("nos-remove", "nos-remove", true), { desc = "Remove Nix package" })

hl.bind("SUPER + X", send_shortcut_once("CTRL", "X"), { desc = "Universal cut" })
hl.bind("SUPER + C", universal_clipboard_shortcut("CTRL", "C", "CTRL", "Insert"), { desc = "Universal copy" })
hl.bind("SUPER + V", universal_clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"), { desc = "Universal paste" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(shell.volume_up), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(shell.volume_down), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(shell.volume_mute), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(shell.mic_mute), { locked = true, repeating = true })

hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl --quiet --class=backlight set +5%"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl --quiet --class=backlight set 5%-"),
	{ locked = true, repeating = true }
)

hl.bind("SUPER + M", monitors.toggle_aspect_ratio, {
	desc = "Toggle single-window max width",
})
