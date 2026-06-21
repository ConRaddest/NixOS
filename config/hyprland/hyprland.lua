-- ============================================================
-- Startup
-- ============================================================

local startup_apps = {
	"nos-lock", -- cold boot enters the same lock surface used after resume
	"uwsm app -- hyprpaper", -- load the wallpaper
	"uwsm app -- qs", -- load quickshell
}

hl.on("hyprland.start", function()
	for _, cmd in ipairs(startup_apps) do
		hl.exec_cmd(cmd)
	end
end)

-- ============================================================
-- Monitors
-- ============================================================

local function assign_workspaces(monitor, workspaces)
	for _, ws in ipairs(workspaces) do
		hl.workspace_rule({ workspace = tostring(ws), monitor = monitor, default = true })
	end
end

assign_workspaces("eDP-1", { 1, 2, 3 })
assign_workspaces("HDMI-A-1", { 4, 5, 6 })

hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60",
	position = "0x0",
	scale = 1,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "3440x1440@174.96",
	position = "1920x0",
	scale = 1,
})

-- ============================================================
-- Config
-- ============================================================

hl.config({
	-- input
	input = {
		accel_profile = "flat",
		sensitivity = 1.5,
		repeat_rate = 35,
		repeat_delay = 200,
	},
	cursor = {
		no_hardware_cursors = true,
	},

	-- cosmetics
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 1,
		layout = "dwindle",
		col = {
			active_border = "rgba(1a1b26ff)",
			inactive_border = "rgba(1a1b26ff)",
		},
	},

	decoration = {
		rounding = 1,
		active_opacity = 0.93,
		inactive_opacity = 0.90,
		fullscreen_opacity = 0.93,
		blur = {
			enabled = true,
			special = true,
			size = 2,
			passes = 3,
			xray = true,
		},
		shadow = {
			enabled = true,
			range = 30,
			render_power = 100,
			color = 0x33000000,
			color_inactive = 0x22000000,
			offset = { 0, 4 },
		},
	},
	animations = { enabled = true },
	layout = {
		single_window_aspect_ratio = { 16, 9 },
	},

	-- misc
	dwindle = { preserve_split = true },
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
	},
})

-- trackpad specific settings
local TOUCHPAD = "msft0001:01-06cb:cd5f-touchpad"
hl.device({
	name = TOUCHPAD,
	accel_profile = "adaptive",
	natural_scroll = true,
	sensitivity = 0.0,
})

-- ============================================================
-- Animations
-- ============================================================

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
	{ enabled = true, leaf = "workspaces", speed = 2, bezier = "fast" },
	{ enabled = true, leaf = "specialWorkspace", speed = 2, bezier = "fast", style = "slidevert" },
	{ enabled = true, leaf = "fade", speed = 1, bezier = "fast" },
}

for _, animation in ipairs(animations) do
	hl.animation(animation)
end

-- ============================================================
-- Keybindings
-- ============================================================

-- launchers
local function place_launcher_on_active_workspace(workspace, monitor)
	for _, win in ipairs(hl.get_windows()) do
		if win.title == "shell-launcher" then
			hl.dispatch(hl.dsp.window.move({ window = win, workspace = workspace }))
			hl.dispatch(hl.dsp.window.move({ window = win, monitor = monitor }))
			hl.dispatch(hl.dsp.window.center({ window = win }))
			hl.dispatch(hl.dsp.focus({ window = win }))
			return
		end
	end
end

local function open_launcher(cmd)
	local workspace = hl.get_active_workspace()
	local monitor = hl.get_active_monitor()
	hl.dispatch(hl.dsp.exec_cmd(cmd))
	hl.timer(function()
		place_launcher_on_active_workspace(workspace, monitor)
	end, { timeout = 120, type = "oneshot" })
end

hl.bind("SUPER + SHIFT + Space", function()
	open_launcher("qs ipc call launcher open")
end)
hl.bind("SUPER + Space", function()
	open_launcher("qs ipc call launcher openSubmenu Apps")
end)
hl.bind("SUPER + ALT + Space", function()
	open_launcher("qs ipc call launcher openSubmenu System")
end)
hl.bind("SUPER + P", hl.dsp.exec_cmd("qs ipc call processes open"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs ipc call bar toggle"))

-- suspend on power off
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("nos-suspend"), { locked = true })

-- apps
local app_binds = {
	{ "SUPER + Return", "kitty" },
	{ "SUPER + B", "firefox" },
}
for _, b in ipairs(app_binds) do
	hl.bind(b[1], hl.dsp.exec_cmd("uwsm app -- " .. b[2]))
end

hl.bind("SUPER + Grave", hl.dsp.workspace.toggle_special("terminal"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- kitty --class yazi --title yazi -e yazi"))

-- workspaces
hl.bind("SUPER + W", function()
	local win = hl.get_active_window()
	if win and win.title == "shell-launcher" then
		hl.dispatch(hl.dsp.exec_cmd("qs ipc call launcher close"))
	else
		hl.dispatch(hl.dsp.window.close())
	end
end)
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

local fullscreen_uses_normal_opacity = true

hl.bind("SUPER + SHIFT + F", function()
	fullscreen_uses_normal_opacity = not fullscreen_uses_normal_opacity
	hl.config({
		decoration = {
			fullscreen_opacity = fullscreen_uses_normal_opacity and 0.93 or 1.0,
		},
	})
end, { desc = "Toggle fullscreen opacity" })
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"))

for _, dir in ipairs({ "left", "right", "up", "down" }) do
	hl.bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
	hl.bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

for ws = 1, 9 do
	hl.bind("SUPER + " .. ws, hl.dsp.focus({ workspace = ws }))
	hl.bind("SUPER + SHIFT + " .. ws, hl.dsp.window.move({ workspace = ws }))
end

-- window resizing
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- hypr shortcuts
hl.bind("CTRL + SHIFT + H", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("CTRL + SHIFT + K", hl.dsp.exec_cmd("hyprpicker"))
hl.bind("CTRL + SHIFT + L", hl.dsp.exec_cmd("nos-lock"))

-- laptop lid suspends the computer
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("nos-suspend"), { locked = true })

-- screenshot
local screenshot_cmd = "mkdir -p ~/Screenshots && "
	.. 'file="$HOME/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png" && '
	.. 'grim -g "$(slurp)" "$file" && wl-copy --type image/png < "$file"'
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(screenshot_cmd))

-- nixos helpers
local function terminal(klass, cmd, pause)
	local tail = pause == false and "" or '; echo; printf "\\033[38;5;141mPress Enter to close...\\033[0m"; read -r'
	return hl.dsp.exec_cmd(
		"uwsm app -- kitty --class "
			.. klass
			.. " --title "
			.. klass
			.. " -e bash -lic '"
			.. cmd
			.. tail
			.. "'"
	)
end

local nixos_binds = {
	{ "SUPER + SHIFT + R", "nixos-refresh", "nos-refresh --offline", false },
	{ "SUPER + SHIFT + B", "nixos-build", "nos-build", false },
	{ "SUPER + SHIFT + U", "nixos-update", "nos-update" },
	{ "SUPER + SHIFT + I", "nixos-install", "nos-install", false },
	{ "SUPER + SHIFT + X", "nixos-remove", "nos-remove", false },
}
for _, b in ipairs(nixos_binds) do
	hl.bind(b[1], terminal(b[2], b[3], b[4]))
end

-- universal copy / paste
local universal_shortcut_pressed = {}

local function send_shortcut_once(mods, key)
	-- Clear any stale synthetic state, then send a short, real-looking tap.
	hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
	hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
	hl.timer(function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
	end, { timeout = 90, type = "oneshot" })
end

local function bind_shortcut(bind, mods, key, desc)
	hl.bind(bind, function()
		if universal_shortcut_pressed[bind] then
			return
		end
		universal_shortcut_pressed[bind] = true
		send_shortcut_once(mods, key)

		-- Safety reset in case Hyprland misses the release event during focus churn.
		hl.timer(function()
			universal_shortcut_pressed[bind] = false
			hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
		end, { timeout = 1200, type = "oneshot" })
	end, { desc = desc })

	hl.bind(bind, function()
		universal_shortcut_pressed[bind] = false
	end, { release = true })
end

bind_shortcut("SUPER + X", "SHIFT", "Delete", "Universal cut")
bind_shortcut("SUPER + C", "CTRL", "Insert", "Universal copy")
bind_shortcut("SUPER + V", "SHIFT", "Insert", "Universal paste")

-- toggle single window aspect ratio
local single_window_aspect_enabled = true
hl.bind("SUPER + M", function()
	single_window_aspect_enabled = not single_window_aspect_enabled
	if single_window_aspect_enabled then
		hl.config({ layout = { single_window_aspect_ratio = { 16, 9 } } })
	else
		hl.config({ layout = { single_window_aspect_ratio = { 0, 0 } } })
	end
end, { desc = "Toggle single-window max width" })

-- media / brightness
local osd = (os.getenv("NOS_DIR") or (os.getenv("HOME") .. "/NixOS")) .. "/scripts/shell/osd.sh"

local media = {
	{ "XF86AudioRaiseVolume", "bash " .. osd .. " volume up" },
	{ "XF86AudioLowerVolume", "bash " .. osd .. " volume down" },
	{ "XF86AudioMute", "bash " .. osd .. " volume mute" },
	{ "XF86AudioMicMute", "bash " .. osd .. " mic mute" },
	{ "XF86MonBrightnessUp", "bash " .. osd .. " brightness up" },
	{ "XF86MonBrightnessDown", "bash " .. osd .. " brightness down" },
}
for _, b in ipairs(media) do
	hl.bind(b[1], hl.dsp.exec_cmd(b[2]), { locked = true, repeating = true })
end

-- ============================================================
-- Window Rules
-- ============================================================

local POPUP_SIZE = { 1300, 800 }

local popup_windows = {
	{ title = "shell-launcher", size = { 700, 710 }, stay_focused = true },
	{ title = "process-manager", size = { 700, 710 } },

	{ title = "wallpaper-picker" },
	{ title = "theme-picker" },
	{ title = "theme-apply" },
	{ title = "screenshot-picker" },
	{ title = "shell-clipboard" },

	{ title = "wifi-manager" },
	{ title = "bluetooth-manager" },
	{ title = "performance-monitor" },
	{ title = "audio-manager" },

	{ title = "windows-install" },
	{ title = "windows-uninstall" },
	{ title = "windows-credentials" },
	{ title = "windows-vm-start" },

	{ title = "nixos-refresh" },
	{ title = "nixos-build" },
	{ title = "nixos-update" },
	{ title = "nixos-check" },
	{ title = "nixos-install" },
	{ title = "nixos-remove" },

	{ title = "webapp-install" },
	{ title = "webapp-uninstall" },

	{ class = "xdg-desktop-portal-gtk" },
	{ class = "termfilechooser" },
	{ class = "1password" },
	{ class = "lazy-docker" },

	{ class = "yazi" },
}

for _, w in ipairs(popup_windows) do
	hl.window_rule({
		match = w.title and { title = w.title } or { class = w.class },
		float = true,
		center = true,
		size = w.size or POPUP_SIZE,
		pin = w.pin,
		stay_focused = w.stay_focused,
	})
end

-- Some apps open a normal Wayland/X11 client that previews the shared screen
-- after a portal screencast starts. Hide those generic sharing-preview windows
-- on a never-used special workspace so they do not take screen space or expose
-- the shared content locally. This is intentionally title-based instead of
-- app/class-based so it works across Teams, Chromium/Electron apps, etc.
hl.window_rule({
	match = { title = ".*(Screen is being shared|Screen Share Active).*" },
	workspace = "special:screenshare-preview silent",
	no_focus = true,
	suppress_event = "activate activatefocus",
})

-- The share picker is a layer-shell surface, not a normal client window, so
-- regular window decoration/blur rules do not apply. Match its layer namespace
-- and apply the same kind of translucent xray blur used by other overlays.
hl.layer_rule({
	match = { namespace = "^ch\\.wysbd\\.hyprland-preview-share-picker$" },
	blur = true,
	xray = true,
	ignore_alpha = 0.01,
})

hl.window_rule({ match = { float = true }, opacity = "0.935 override" })
