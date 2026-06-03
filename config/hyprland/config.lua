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
