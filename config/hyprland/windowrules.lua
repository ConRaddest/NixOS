-- Mako notifications are layer surfaces; their animations are controlled by
-- Hyprland, not mako. Disable animations only for mako's layer namespace.
hl.layer_rule({
	match = { namespace = "notifications" },
	no_anim = true,
})

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
		opacity = "0.98 override",
	})
end

hl.window_rule({
	match = { class = "1password" },
	float = true,
	center = true,
	size = { 1300, 800 },
})
