-- Settings
hl.config({
	input = {
		accel_profile = "flat",
		sensitivity = 1.5,
	},
	cursor = {
		-- Render the cursor in software so Wayland screen sharing can capture it.
		no_hardware_cursors = true,
	},
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 0,
		layout = "dwindle",
	},
	decoration = {
		rounding = 0,
		active_opacity = 0.93,
		inactive_opacity = 0.90,
		blur = {
			enabled = true,
			special = true,
			size = 5,
			passes = 2,
		},
	},
	animations = { enabled = true },
	layout = {
		-- Disabled by default. Toggle with SUPER+M to constrain a single tiled
		-- window to 16:9 on ultrawide workspaces.
		single_window_aspect_ratio = { 16, 9 },
	},
	dwindle = { preserve_split = true },
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
	},
})

-- Per-device settings targeting your trackpad specifically
hl.device({
	name = "msft0001:01-06cb:cd5f-touchpad",
	accel_profile = "adaptive",
	natural_scroll = true,
	sensitivity = 0.0,
})
