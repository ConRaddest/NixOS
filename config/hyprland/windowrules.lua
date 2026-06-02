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
	size = { 450, 400 },
})

-- Teams/Chromium notification popups
-- These should normally go through mako via native notifications. If Chromium
-- or Teams still creates a small auxiliary window, keep it floating instead of
-- letting Hyprland tile it as a half-screen window.
local teams_notification_titles = {
	".*[Nn]otification.*",
	".*[Tt]oast.*",
}
for _, title in ipairs(teams_notification_titles) do
	hl.window_rule({
		match = { class = "TeamsPWA", title = title },
		float = true,
		pin = true,
		size = { 420, 140 },
		move = { "100%-440", 24 },
	})
end

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

-- File pickers
local file_explorers = {
	"xdg-desktop-portal-gtk",
	"org.gnome.Nautilus",
	"1password",
}
for _, class in ipairs(file_explorers) do
	hl.window_rule({
		match = { class = class },
		float = true,
		center = true,
		size = { 1300, 800 },
	})
end
