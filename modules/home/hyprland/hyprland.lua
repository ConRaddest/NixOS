-- Load Nix-built plugins before applying their config.
require("nix.plugins")
pcall(require, "nix.input")

-- ============================================================
-- monitors
-- ============================================================

local monitorWorkspaces = {}

local function assignWorkspaces(monitor, workspaces)
	monitorWorkspaces[monitor] = workspaces
	for _, ws in ipairs(workspaces) do
		hl.workspace_rule({ workspace = tostring(ws), monitor = monitor, default = true })
	end
end

local configuredMonitors = require("nix.monitors")
for _, monitor in ipairs(configuredMonitors) do
	assignWorkspaces(monitor.output, monitor.workspaces)
	hl.monitor({
		output = monitor.output,
		mode = monitor.mode,
		position = monitor.position,
		scale = monitor.scale,
	})
end

-- ============================================================
-- visuals
-- ============================================================
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
		border_size = 2,
		layout = "dwindle",
		col = {
			active_border = "rgba(1a1b26ff)",
			inactive_border = "rgba(1a1b26ff)",
		},
	},

	decoration = {
		rounding = 8,
		active_opacity = 0.95,
		inactive_opacity = 0.93,
		fullscreen_opacity = 1.0,
		blur = {
			enabled = true,
			special = true,
			size = 2,
			passes = 3,
			xray = true,
		},
		shadow = {
			enabled = true,
			range = 50,
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
	dwindle = { preserve_split = true, smart_split = true },
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
	},
})

-- Stylix colors generated from the shared Base16 palette.
-- require("nix.colors")

-- ============================================================
-- animations
-- ============================================================

-- fast and snappy, macos feels
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
	{ enabled = true, leaf = "windows",          speed = 2, spring = "spring" },
	{ enabled = true, leaf = "windowsOut",       speed = 2, spring = "spring" },
	{ enabled = true, leaf = "workspaces",       speed = 2, bezier = "fast",  style = "slidevert" },
	{ enabled = true, leaf = "specialWorkspace", speed = 2, bezier = "fast",  style = "slidevert" },
	{ enabled = true, leaf = "fade",             speed = 1, bezier = "fast" },
}

for _, animation in ipairs(animations) do
	hl.animation(animation)
end

-- ============================================================
-- keybinds
-- ============================================================

-- dms
hl.bind("SUPER + Space", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("dms ipc call processlist toggle"))

-- suspend on power button press
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
-- laptop lid suspends the computer
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })

-- apps
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("terminal"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- kitty --class yazi --title yazi -e yazi"))
hl.bind("SUPER + Return", hl.dsp.exec_cmd("uwsm app -- kitty"))

-- workspaces
hl.bind("SUPER + W", hl.dsp.window.close())
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))

hl.bind(
	"SUPER + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ desc = "Toggle fullscreen" }
)

-- quick switch between two most recent workspaces
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "previous" }))

-- workspace overview
hl.bind("SUPER + A", function()
	hl.plugin.scrolloverview.overview("toggle")
end)

-- scroll through the workspaces with super + scroll
local function scrollWorkspace(offset)
	local monitor = hl.get_active_monitor()
	local workspace = monitor and monitor.active_workspace
	local workspaces = monitor and monitorWorkspaces[monitor.name] or { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
	if not workspace then
		return
	end

	local lastUsedIndex = 0
	for index, id in ipairs(workspaces) do
		local candidate = hl.get_workspace(id)
		if candidate and not candidate.is_empty then
			lastUsedIndex = index
		end
	end
	local maxIndex = math.min(math.max(lastUsedIndex + 1, 1), #workspaces)

	for index, id in ipairs(workspaces) do
		local targetIndex = index + offset
		if id == workspace.id and targetIndex >= 1 and targetIndex <= maxIndex then
			hl.dispatch(hl.dsp.focus({ workspace = workspaces[targetIndex] }))
			return
		end
	end
end

hl.bind("SUPER + mouse_up", function()
	scrollWorkspace(1)
end)
hl.bind("SUPER + mouse_down", function()
	scrollWorkspace(-1)
end)

-- move monitors to and from workspaces
local directions = { "left", "right", "up", "down" }
local oppositeDirection = { left = "right", right = "left", up = "down", down = "up" }

local function rangesOverlap(aStart, aEnd, bStart, bEnd)
	return math.min(aEnd, bEnd) > math.max(aStart, bStart)
end

local function hasTiledWindowInDirection(window, direction)
	local workspace = window.workspace
	if not workspace then
		return false
	end

	local position = window.at
	local size = window.size
	local centerX = position.x + size.x / 2
	local centerY = position.y + size.y / 2

	for _, other in ipairs(hl.get_workspace_windows(workspace)) do
		if other ~= window and not other.floating and not other.hidden then
			local otherPosition = other.at
			local otherSize = other.size
			local otherCenterX = otherPosition.x + otherSize.x / 2
			local otherCenterY = otherPosition.y + otherSize.y / 2
			local overlapsHorizontally =
					rangesOverlap(position.x, position.x + size.x, otherPosition.x, otherPosition.x + otherSize.x)
			local overlapsVertically =
					rangesOverlap(position.y, position.y + size.y, otherPosition.y, otherPosition.y + otherSize.y)

			if
					(direction == "left" and otherCenterX < centerX and overlapsVertically)
					or (direction == "right" and otherCenterX > centerX and overlapsVertically)
					or (direction == "up" and otherCenterY < centerY and overlapsHorizontally)
					or (direction == "down" and otherCenterY > centerY and overlapsHorizontally)
			then
				return true
			end
		end
	end

	return false
end

local function smartMoveWindow(direction)
	local window = hl.get_active_window()
	local layout = window and window.layout
	if not window or window.floating or window.fullscreen ~= 0 or not layout or layout.name ~= "dwindle" then
		hl.dispatch(hl.dsp.window.move({ direction = direction }))
		return
	end

	-- Keep an existing row/column intact. At its outer edge, the window in the
	-- opposite direction still identifies the current split axis.
	if
			hasTiledWindowInDirection(window, direction)
			or hasTiledWindowInDirection(window, oppositeDirection[direction])
	then
		hl.dispatch(hl.dsp.window.move({ direction = direction }))
		return
	end

	-- Movement perpendicular to the current split rotates that split. The
	-- focused leaf may then be on the opposite side, so swap its two siblings.
	hl.dispatch(hl.dsp.layout("togglesplit"))
	if hasTiledWindowInDirection(window, direction) then
		hl.dispatch(hl.dsp.layout("swapsplit"))
	end
end

for _, dir in ipairs(directions) do
	hl.bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
	hl.bind("SUPER + SHIFT + " .. dir, function()
		smartMoveWindow(dir)
	end)
end

-- change workspaces
for ws = 1, 9 do
	hl.bind("SUPER + " .. ws, hl.dsp.focus({ workspace = ws }))
	hl.bind("SUPER + SHIFT + " .. ws, hl.dsp.window.move({ workspace = ws }))
end

-- window resizing
-- expand horizontally (increase width)
hl.bind("SUPER + equal", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))

-- shrink horizontally (decrease width)
hl.bind("SUPER + minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- color picker
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("hyprpicker"))

-- screenshot
local screenshot_cmd = "mkdir -p ~/Screenshots && "
		.. 'file="$HOME/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png" && '
		.. 'grim -g "$(slurp)" "$file" && wl-copy --type image/png < "$file"'
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(screenshot_cmd))

-- NOS helpers
local function openTerminal(klass, cmd, pause)
	return hl.dsp.exec_cmd(
		"uwsm app -- kitty --class " .. klass .. " --title " .. klass .. " -e bash -lic '" .. cmd .. "'"
	)
end

hl.bind("SUPER + SHIFT + B", openTerminal("nos-build", "nos-build", false), { desc = "Build NixOS configuration" })
hl.bind("SUPER + SHIFT + U", openTerminal("nos-update", "nos-update", true), { desc = "Update NixOS configuration" })
hl.bind("SUPER + SHIFT + I", openTerminal("nos-install", "nos-install", false), { desc = "Install Nix package" })
hl.bind("SUPER + SHIFT + X", openTerminal("nos-remove", "nos-remove", false), { desc = "Remove Nix package" })
hl.bind("SUPER + SHIFT + R", openTerminal("nos-refresh", "nos-refresh", false), { desc = "Refresh Home Manager" })

-- universal copy / paste
local universal_shortcut_pressed = {}

local function sendShortcutOnce(mods, key)
	-- Clear any stale synthetic state, then send a short, real-looking tap.
	hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
	hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
	hl.timer(function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
	end, { timeout = 90, type = "oneshot" })
end

local function bindShortcut(bind, mods, key, desc, windowsMods, windowsKey)
	hl.bind(bind, function()
		if universal_shortcut_pressed[bind] then
			return
		end
		universal_shortcut_pressed[bind] = true

		local shortcutMods = mods
		local shortcutKey = key
		local win = hl.get_active_window()
		if win and win.class == "windows-vm" then
			shortcutMods = windowsMods or mods
			shortcutKey = windowsKey or key
		end
		sendShortcutOnce(shortcutMods, shortcutKey)

		-- Safety reset in case Hyprland misses the release event during focus churn.
		hl.timer(function()
			universal_shortcut_pressed[bind] = false
			hl.dispatch(hl.dsp.send_key_state({ mods = shortcutMods, key = shortcutKey, state = "up" }))
		end, { timeout = 1200, type = "oneshot" })
	end, { desc = desc })

	hl.bind(bind, function()
		universal_shortcut_pressed[bind] = false
	end, { release = true })
end

bindShortcut("SUPER + X", "SHIFT", "Delete", "Universal cut")
bindShortcut("SUPER + C", "CTRL", "Insert", "Universal copy", "CTRL", "C")
bindShortcut("SUPER + V", "SHIFT", "Insert", "Universal paste", "CTRL", "V")

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
local media = {
	{ "XF86AudioRaiseVolume",  "dms ipc call audio increment 5" },
	{ "XF86AudioLowerVolume",  "dms ipc call audio decrement 5" },
	{ "XF86AudioMute",         "dms ipc call audio mute" },
	{ "XF86AudioMicMute",      "dms ipc call audio micmute" },
	{ "XF86MonBrightnessUp",   'dms ipc call brightness increment 5 ""' },
	{ "XF86MonBrightnessDown", 'dms ipc call brightness decrement 5 ""' },
}
for _, b in ipairs(media) do
	hl.bind(b[1], hl.dsp.exec_cmd(b[2]), { locked = true, repeating = true })
end

-- ============================================================
-- windows and layer rules
-- ============================================================
local popupSize = { 1000, 650 }
local popup_windows = {
	{ title = "windows-install" },
	{ title = "windows-uninstall" },
	{ title = "windows-credentials" },
	{ title = "windows-vm-start" },

	{ title = "nos-build",             size = popupSize },
	{ title = "nos-refresh",           size = popupSize },
	{ title = "nos-update",            size = popupSize },
	{ title = "nos-install",           size = popupSize },
	{ title = "nos-remove",            size = popupSize },

	{ class = "xdg-desktop-portal-gtk" },
	{ class = "termfilechooser" },
	{ class = "1password" },
	{ class = "lazy-docker" },
}

for _, w in ipairs(popup_windows) do
	hl.window_rule({
		match = w.title and { title = w.title } or { class = w.class },
		float = true,
		center = true,
		size = w.size or { 1300, 800 },
		pin = w.pin,
		stay_focused = w.stay_focused,
	})
end

hl.window_rule({
	match = { title = ".*(Screen is being shared|Screen Share Active).*" },
	workspace = "special:screenshare-preview silent",
	no_focus = true,
	suppress_event = "activate activatefocus",
})

hl.layer_rule({
	match = { namespace = "^ch\\.wysbd\\.hyprland-preview-share-picker$" },
	blur = true,
	xray = true,
	ignore_alpha = 0.01,
})

hl.window_rule({ match = { float = true }, opacity = "0.935 override 0.935 override 1.0 override" })

-- Electron renders transparent rounded corners on native VS Code dialogs.
-- Force these surfaces opaque to prevent corner artifacts.
hl.window_rule({
	match = { class = "^code$", title = "^Visual Studio Code$", float = true },
	opaque = true,
	opacity = "1.0 override 1.0 override 1.0 override",
})

require("dms.binds")
require("dms.binds-user")
require("dms.outputs")
require("dms.windowrules")
-- require("dms.layout")
require("dms.cursor")
