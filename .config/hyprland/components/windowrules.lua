-- Floating panes
-- Managers
local managers = {
  "wallpaper-picker",
  "wifi-manager",
  "bluetooth-manager",
  "performance-monitor",
  "audio-manager",
  "windows-install",
  "windows-credentials",
  "nixos-refresh",
  "nixos-build",
  "nixos-update",
  "nixos-check",
}
for _, name in ipairs(managers) do
  hl.window_rule({
    match = { title = name },
    float = true,
    center = true,
    size = { 1100, 650 },
  })
end

-- Shell launcher
local launchers = {
  "shell-launcher",
  "shell-clipboard",
}
for _, name in ipairs(launchers) do
  hl.window_rule({
    match = { title = name },
    float = true,
    center = true,
    size = { 450, 400 },
  })
end

hl.window_rule({
  match = { title = "Select what to share" },
  float = true,
  center = true,
  size = { 800, 600 },
})

hl.window_rule({
  match = { class = "1password", title = "1Password" },
  float = true,
  center = true,
  size = { 500, 500 },
})

-- File pickers
local file_explorers = {
  "xdg-desktop-portal-gtk",
  "org.gnome.Nautilus",
}
for _, class in ipairs(file_explorers) do
  hl.window_rule({
    match = { class = class },
    float = true,
    center = true,
    size = { 1300, 800 },
  })
end
