local windows = {
	{ title = "windows-install" },
	{ title = "windows-uninstall" },
	{ title = "windows-credentials" },
	{ title = "windows-vm-start" },
	{ title = "nos-command-install" },
	{ title = "nos-command-remove" },
	{ class = "nos-command-build" },
	{ class = "nos-command-refresh" },
	{ class = "nos-command-update" },
	{ class = "xdg-desktop-portal-gtk" },
	{ class = "termfilechooser" },
	{ class = "1password" },
	{ class = "lazy-docker" },
	{ class = "org.gnome.Calculator", size = { 360, 620 } },
}

hl.window_rule({
	match = { class = "nos-screensaver" },
	float = true,
	fullscreen = true,
})

for _, window in ipairs(windows) do
	hl.window_rule({
		match = window.title and { title = window.title } or { class = window.class },
		float = true,
		center = true,
		size = window.size or { 1000, 650 },
	})
end
