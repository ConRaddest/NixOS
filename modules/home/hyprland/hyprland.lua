require("nix.plugins")
require("nix.colors")
require("nix.theme")
pcall(require, "nix.input")

local shell = require("nix.shell")
local configuredMonitors = require("nix.monitors")
local monitorWorkspaces = {}
local workspaceAspectRatio = {}
local windows = {
	{ title = "windows-install" },
	{ title = "windows-uninstall" },
	{ title = "windows-credentials" },
	{ title = "windows-vm-start" },

	{ title = "nos-install" },
	{ title = "nos-remove" },
	{ class = "nos-build" },
	{ class = "nos-refresh" },
	{ class = "nos-update" },

	{ class = "xdg-desktop-portal-gtk" },
	{ class = "termfilechooser" },
	{ class = "1password" },
	{ class = "lazy-docker" },
	{ class = "org.gnome.Calculator", size = { 360, 616 } },
}

for _, w in ipairs(windows) do
	hl.window_rule({
		match = w.title and { title = w.title } or { class = w.class },
		float = true,
		center = true,
		size = w.size or { 1000, 650 },
		pin = w.pin,
		stay_focused = w.stay_focused,
	})
end

local function applyWorkspaceAspectRatio(workspace)
	local enabled = workspaceAspectRatio[workspace.id]
	if enabled == nil then
		enabled = true
	end

	local ratio = enabled and { 16, 9 } or { 0, 0 }
	hl.config({ layout = { single_window_aspect_ratio = ratio } })
end

hl.on("workspace.active", applyWorkspaceAspectRatio)

local function assignWorkspaces(monitor, workspaces)
	monitorWorkspaces[monitor] = workspaces
	for _, ws in ipairs(workspaces) do
		hl.workspace_rule({ workspace = tostring(ws), monitor = monitor, default = true, persistent = true })
	end
end

local function scrollWorkspace(offset)
	local monitor = hl.get_active_monitor()
	if not monitor or not monitor.active_workspace then
		return
	end

	local workspaces = monitorWorkspaces[monitor.name] or {}
	for index, id in ipairs(workspaces) do
		if id == monitor.active_workspace.id then
			local target = workspaces[index + offset]
			if target then
				hl.dispatch(hl.dsp.focus({ workspace = target }))
			end
			return
		end
	end
end

for _, monitor in ipairs(configuredMonitors) do
	assignWorkspaces(monitor.output, monitor.workspaces)
	hl.monitor({
		output = monitor.output,
		mode = monitor.mode,
		position = monitor.position,
		scale = monitor.scale,
	})
end

local function openTerminal(klass, cmd, keepOpen)
	local suffix = keepOpen and "; exec fish" or ""
	return hl.dsp.exec_cmd(
		"uwsm app -- kitty --class " .. klass .. " --title " .. klass .. " -e bash -lic '" .. cmd .. suffix .. "'"
	)
end

hl.config({
	plugin = {
		scrolloverview = {
			gesture_distance = 300,
			scale = 0.5,
			workspace_gap = 100,
			layout = "vertical",
			wallpaper = 0,
			blur = false,
			shadow = {
				enabled = false,
			},
		},
	},

	input = {
		accel_profile = "flat",
		sensitivity = 1.5,
		repeat_rate = 35,
		repeat_delay = 200,
	},
	cursor = {
		no_hardware_cursors = true,
	},

	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 0,
		layout = "dwindle",
	},

	decoration = {
		rounding = 8,
		active_opacity = 0.98,
		inactive_opacity = 0.96,
		fullscreen_opacity = 1.0,
		blur = {
			enabled = true,
			special = true,
			size = 3,
			passes = 3,
			xray = false,
		},
		shadow = {
			enabled = true,
			range = 12,
			render_power = 3,
			color = 0x33000000,
			color_inactive = 0x22000000,
			offset = { 0, 4 },
		},
	},
	animations = { enabled = true },
	layout = {
		single_window_aspect_ratio = { 16, 9 },
	},

	dwindle = { preserve_split = true, smart_split = false },
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
	},
})

hl.curve("spring", {
	type = "spring",
	mass = 1,
	stiffness = 105,
	dampening = 19,
})

hl.curve("fast", {
	type = "bezier",
	points = { { 0.05, 0.7 }, { 0.1, 1.0 } },
})

local animations = {
	{ enabled = true, leaf = "windows", speed = 2, spring = "spring" },
	{ enabled = true, leaf = "windowsOut", speed = 2, spring = "spring" },
	{ enabled = true, leaf = "workspaces", speed = 2, bezier = "fast", style = "slidevert" },
	{ enabled = true, leaf = "specialWorkspace", speed = 2, bezier = "fast", style = "slidevert" },
	{ enabled = true, leaf = "fade", speed = 1, bezier = "fast" },
}

for _, animation in ipairs(animations) do
	hl.animation(animation)
end

hl.bind("SUPER + Space", hl.dsp.exec_cmd(shell.launcher))
hl.bind("SUPER + P", hl.dsp.exec_cmd(shell.process_list))
hl.bind("SUPER + I", hl.dsp.exec_cmd(shell.bar_toggle))

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
	scrollWorkspace(1)
end)
hl.bind("SUPER + mouse_down", function()
	scrollWorkspace(-1)
end)

local directions = { "left", "right", "up", "down" }
for _, dir in ipairs(directions) do
	hl.bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
	hl.bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

for ws = 1, 9 do
	hl.bind("SUPER + " .. ws, hl.dsp.focus({ workspace = ws }))
	hl.bind("SUPER + SHIFT + " .. ws, hl.dsp.window.move({ workspace = ws }))
end

hl.bind("SUPER + equal", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind("SUPER + minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("hyprpicker"))

local screenshot_cmd = "mkdir -p ~/Screenshots && "
	.. 'file="$HOME/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png" && '
	.. 'grim -g "$(slurp)" "$file" && wl-copy --type image/png < "$file"'
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(screenshot_cmd))

hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("uwsm app -- nos-build"), { desc = "Build NixOS configuration" })
hl.bind("SUPER + SHIFT + U", hl.dsp.exec_cmd("uwsm app -- nos-update"), { desc = "Update NixOS configuration" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("uwsm app -- nos-refresh"), { desc = "Refresh Home Manager" })
hl.bind("SUPER + SHIFT + I", openTerminal("nos-install", "nos-install", true), { desc = "Install Nix package" })
hl.bind("SUPER + SHIFT + X", openTerminal("nos-remove", "nos-remove", true), { desc = "Remove Nix package" })

hl.bind("SUPER + X", hl.dsp.exec_cmd("wtype -M shift -k delete -m shift"), { desc = "Universal cut" })
hl.bind("SUPER + C", hl.dsp.exec_cmd("wtype -M ctrl -k insert -m ctrl"), { desc = "Universal copy" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("wtype -M shift -k insert -m shift"), { desc = "Universal paste" })

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

hl.bind("SUPER + M", function()
	local monitor = hl.get_active_monitor()
	local workspace = monitor and monitor.active_workspace
	if not workspace then
		return
	end

	local enabled = workspaceAspectRatio[workspace.id]
	workspaceAspectRatio[workspace.id] = enabled == false
	applyWorkspaceAspectRatio(workspace)
end, { desc = "Toggle single-window max width for workspace" })

-- hl.window_rule({
-- 	match = { title = ".*(Screen is being shared|Screen Share Active).*" },
-- 	workspace = "special:screenshare-preview silent",
-- 	no_focus = true,
-- 	suppress_event = "activate activatefocus",
-- })

shell.setup()
