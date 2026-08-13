hl.config({
	plugin = {
		scrolloverview = {
			gesture_distance = 300,
			scale = 0.5,
			workspace_gap = 100,
			layout = "vertical",
			wallpaper = 0,
			blur = false,
			input = { scroll_event_delay = 0 },
			shadow = { enabled = false },
		},
	},
	input = {
		accel_profile = "flat",
		sensitivity = 1.5,
		repeat_rate = 35,
		repeat_delay = 200,
	},
	binds = { scroll_event_delay = 0 },
	cursor = { no_hardware_cursors = true },
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 0,
		layout = "dwindle",
	},
	decoration = {
		rounding = 8,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		fullscreen_opacity = 1.0,
		blur = { enabled = false },
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
	layout = { single_window_aspect_ratio = { 16, 9 } },
	dwindle = {
		preserve_split = true,
		smart_split = false,
	},
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
	},
})
