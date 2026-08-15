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

local function open_workspace_terminal()
	if active_window_is_terminal() then
		send_shortcut_once("CTRL SHIFT", "F12")()
	else
		hl.dispatch(hl.dsp.exec_cmd("uwsm app -- kitty"))
	end
end

local function bind(keys, description, dispatcher, options)
	assert(description and description ~= "", "Keybind description is required for " .. keys)
	options = options or {}
	options.desc = description
	return hl.bind(keys, dispatcher, options)
end

bind("SUPER + Space", "Open application launcher", hl.dsp.exec_cmd(shell.launcher))
bind("SUPER + P", "Open process list", hl.dsp.exec_cmd(shell.process_list))

bind("XF86PowerOff", "Suspend system", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
bind("switch:on:Lid Switch", "Suspend when lid closes", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })

bind("SUPER + S", "Toggle terminal workspace", hl.dsp.workspace.toggle_special("terminal"))
bind("SUPER + E", "Open file manager", hl.dsp.exec_cmd("uwsm app -- kitty --class yazi --title yazi -e yazi"))
bind("SUPER + Return", "Open terminal", open_workspace_terminal)
bind("SUPER + W", "Close active window", hl.dsp.window.close())
bind("SUPER + J", "Toggle split direction", hl.dsp.layout("togglesplit"))
bind("SUPER + T", "Toggle floating window", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + F", "Toggle fullscreen window", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind("SUPER + Tab", "Focus previous workspace", hl.dsp.focus({ workspace = "previous" }))

bind("SUPER + mouse_up", "Focus next workspace", function()
	monitors.scroll_workspace(1)
end)
bind("SUPER + mouse_down", "Focus previous workspace", function()
	monitors.scroll_workspace(-1)
end)

for _, direction in ipairs({ "left", "right", "up", "down" }) do
	bind("SUPER + " .. direction, "Focus window " .. direction, hl.dsp.focus({ direction = direction }))
	bind(
		"SUPER + SHIFT + " .. direction,
		"Move window " .. direction,
		hl.dsp.window.move({ direction = direction })
	)
end

for workspace = 1, 9 do
	bind("SUPER + " .. workspace, "Focus workspace " .. workspace, hl.dsp.focus({ workspace = workspace }))
	bind(
		"SUPER + SHIFT + " .. workspace,
		"Move window to workspace " .. workspace,
		hl.dsp.window.move({ workspace = workspace })
	)
end

bind(
	"SUPER + equal",
	"Increase window width",
	hl.dsp.window.resize({ x = 100, y = 0, relative = true }),
	{ repeating = true }
)
bind(
	"SUPER + minus",
	"Decrease window width",
	hl.dsp.window.resize({ x = -100, y = 0, relative = true }),
	{ repeating = true }
)
bind("SUPER + mouse:272", "Drag window", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })
bind(
	"SUPER + SHIFT + K",
	"Pick screen colour and copy hex code",
	hl.dsp.exec_cmd("hyprpicker --autocopy --format=hex --lowercase-hex")
)
bind("SUPER + CTRL + S", "Start Matrix screensaver", hl.dsp.exec_cmd("nos-screensaver"))

local screenshot_command = "mkdir -p ~/Screenshots && "
	.. 'file="$HOME/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png" && '
	.. 'grim -g "$(slurp)" "$file" && wl-copy --type image/png < "$file"'
bind("SUPER + SHIFT + S", "Capture screen region", hl.dsp.exec_cmd(screenshot_command))

bind("SUPER + SHIFT + B", "Build system configuration", hl.dsp.exec_cmd("uwsm app -- nos-build"))
bind("SUPER + SHIFT + U", "Update system configuration", hl.dsp.exec_cmd("uwsm app -- nos-update"))
bind("SUPER + SHIFT + R", "Refresh Home Manager", hl.dsp.exec_cmd("uwsm app -- nos-refresh"))
bind("SUPER + SHIFT + I", "Install Nix package", open_terminal("nos-install", "nos-install", true))
bind("SUPER + SHIFT + X", "Remove Nix package", open_terminal("nos-remove", "nos-remove", true))

bind("SUPER + X", "Universal cut", send_shortcut_once("CTRL", "X"))
bind("SUPER + C", "Universal copy", universal_clipboard_shortcut("CTRL", "C", "CTRL", "Insert"))
bind("SUPER + V", "Universal paste", universal_clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"))

bind("XF86AudioRaiseVolume", "Raise audio volume", hl.dsp.exec_cmd(shell.volume_up), {
	locked = true,
	repeating = true,
})
bind("XF86AudioLowerVolume", "Lower audio volume", hl.dsp.exec_cmd(shell.volume_down), {
	locked = true,
	repeating = true,
})
bind("XF86AudioMute", "Toggle audio mute", hl.dsp.exec_cmd(shell.volume_mute), {
	locked = true,
	repeating = true,
})
bind("XF86AudioMicMute", "Toggle microphone mute", hl.dsp.exec_cmd(shell.mic_mute), {
	locked = true,
	repeating = true,
})

bind(
	"XF86MonBrightnessUp",
	"Raise display brightness",
	hl.dsp.exec_cmd("brightnessctl --quiet --class=backlight set +5%"),
	{ locked = true, repeating = true }
)
bind(
	"XF86MonBrightnessDown",
	"Lower display brightness",
	hl.dsp.exec_cmd("brightnessctl --quiet --class=backlight set 5%-"),
	{ locked = true, repeating = true }
)

bind("SUPER + M", "Toggle single-window max width", monitors.toggle_aspect_ratio)
