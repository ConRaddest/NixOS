hl.config({
	general = {
		col = {
			-- Match background to hide Hyprland xray border artifacts.
			active_border = "rgb(@background@)",
			inactive_border = "rgb(@background@)",
		},
	},
	group = {
		col = {
			border_active = "rgb(@accent@)",
			border_inactive = "rgb(@muted@)",
			border_locked_active = "rgb(@cyan@)",
			border_locked_inactive = "rgb(@muted@)",
		},
	},
})
