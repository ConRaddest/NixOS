local POPUP_SIZE = { 1300, 800 }

local popup_windows = {
	{ title = "shell-launcher", size = { 375, 400 } },

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

	{ title = "webapp-install" },
	{ title = "webapp-uninstall" },

	{ class = "xdg-desktop-portal-gtk" },
	{ class = "org.gnome.Nautilus" },
	{ class = "1password" },
}

for _, w in ipairs(popup_windows) do
	hl.window_rule({
		match = w.title and { title = w.title } or { class = w.class },
		float = true,
		center = true,
		size = w.size or POPUP_SIZE,
	})
end
