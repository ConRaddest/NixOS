-- shell launcher
hl.window_rule({
  match = { title = "shell-launcher" },
  float = true,
  size = { 450, 400 },
})

-- Move the launcher to the correct monitor on every open.
-- The window fully unmaps when closed, so window.open fires on each open.
-- We track the user's last active monitor (excluding the launcher itself)
-- and move the launcher there when it maps.
local launcher_target_monitor = ""

hl.on("window.active", function(w)
  local title = w.title or ""
  if title == "shell-launcher" then return end
  local mon = w.monitor
  if type(mon) == "string" then
    launcher_target_monitor = mon
  elseif mon ~= nil then
    launcher_target_monitor = mon.name or ""
  end
end)

hl.on("window.open", function(w)
  local title = w.title or ""
  if title ~= "shell-launcher" then return end
  if launcher_target_monitor == "" then return end
  hl.dispatch(hl.dsp.window.move({ monitor = launcher_target_monitor }))
  hl.dispatch(hl.dsp.window.center())
end)

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
