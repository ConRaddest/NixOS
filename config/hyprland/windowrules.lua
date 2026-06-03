-- shell launcher
hl.window_rule({
	match = { title = "shell-launcher" },
	float = true,
	size = { 375, 400 },
})

-- Managers
local managers = {
	"wallpaper-picker",
	"theme-picker",
	"theme-apply",
	"screenshot-picker",
	"shell-clipboard",

	"wifi-manager",
	"bluetooth-manager",
	"performance-monitor",
	"audio-manager",

	"windows-install",
	"windows-uninstall",
	"windows-credentials",
	"windows-vm-start",

	"nixos-refresh",
	"nixos-build",
	"nixos-update",
	"nixos-check",

	"webapp-install",
	"webapp-uninstall",
}
for _, title in ipairs(managers) do
	hl.window_rule({
		match = { title = title },
		float = true,
		center = true,
		size = { 1300, 800 },
	})
end

-- File pickers / file managers
local themed_file_windows = {
	"xdg-desktop-portal-gtk",
	"org.gnome.Nautilus",
}
for _, class in ipairs(themed_file_windows) do
	hl.window_rule({
		match = { class = class },
		float = true,
		center = true,
		size = { 1300, 800 },
		-- opacity = "0.98 override",
	})
end

hl.window_rule({
	match = { class = "1password" },
	float = true,
	center = true,
	size = { 1300, 800 },
})

hl.window_rule({
	-- Chromium derives app-mode classes from the URL, and Google Calendar may
	-- include account/path details such as `__calendar_u_0_r`. Match only the
	-- stable host prefix so this works across accounts and installs.
	match = { class = "chrome-calendar\\.google\\.com.*" },
	float = true,
	center = true,
	size = { 1900, 1100 },
})
