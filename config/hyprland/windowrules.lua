-- shell launcher
hl.window_rule({
  match = { title = "shell-launcher" },
  float = true,
  size = { 450, 400 },
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
