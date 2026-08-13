local windows = {
	{ title = "windows-install" },
	{ title = "windows-uninstall" },
	{ title = "windows-credentials" },
	{ title = "windows-vm-start" },
	{ title = "nos-install" },
	{ title = "nos-remove" },
	{ class = "nos-build" },
	{ class = "nos-refresh" },
	{ class = "nos-update" },
	{ class = "xdg-desktop-portal-gtk" },
	{ class = "termfilechooser" },
	{ class = "1password" },
	{ class = "lazy-docker" },
	{ class = "org.gnome.Calculator", size = { 360, 620 } },
}

for _, window in ipairs(windows) do
	hl.window_rule({
		match = window.title and { title = window.title } or { class = window.class },
		float = true,
		center = true,
		size = window.size or { 1000, 650 },
	})
end
