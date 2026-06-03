-- shell launcher
hl.window_rule({
	match = { title = "shell-launcher" },
	float = true,
	size = { 375, 400 },
})

-- title based windows
local title_windows = {
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
for _, title in ipairs(title_windows) do
	hl.window_rule({
		match = { title = title },
		float = true,
		center = true,
		size = { 1300, 800 },
	})
end

-- class based windows
local class_windows = {
	"xdg-desktop-portal-gtk",
	"org.gnome.Nautilus",
	"1password",
}
for _, class in ipairs(class_windows) do
	hl.window_rule({
		match = { class = class },
		float = true,
		center = true,
		size = { 1300, 800 },
	})
end
