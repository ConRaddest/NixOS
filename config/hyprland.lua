-- Startup
hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm app -s s -- lxqt-policykit-agent")
  hl.exec_cmd("uwsm app -- hyprpaper")
  hl.exec_cmd("uwsm app -- qs")
  hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")
end)


-- Monitor
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Disable the laptop panel while the lid is closed, and restore it when opened.
-- hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("hyprctl keyword monitor eDP-1,disable"), { locked = true })
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor eDP-1,preferred,auto,1"), { locked = true })

hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", default = true })

hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", default = true })

-- Settings
hl.config({
  input = {
    kb_layout = "za",
    follow_mouse = 1,
    touchpad = { natural_scroll = true },
  },
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 0,

    layout = "dwindle",
  },
  decoration = {
    rounding = 0,
    active_opacity = 0.98,
    inactive_opacity = 0.95,
    blur = {
      enabled = true,
      special = true,
      size = 6,
      passes = 2,
    },
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
})

-- Animations
hl.curve("fast", {
  type = "bezier",
  points = { { 0.05, 0.7 }, { 0.1, 1.0 } },
})

local animations = {
  { leaf = "windows",    speed = 4,  bezier = "fast" },
  { leaf = "windowsOut", speed = 4,  bezier = "fast" },
  { leaf = "border",     speed = 8,  bezier = "fast" },
  { leaf = "fade",             speed = 4,  bezier = "fast" },
  { leaf = "workspaces",       speed = 4,  bezier = "fast" },
  { leaf = "specialWorkspace", speed = 4,  bezier = "fast", style = "slidevert" },
}

for _, animation in ipairs(animations) do
  animation.enabled = true
  hl.animation(animation)
end

-- Keybinds
-- Launchers
hl.bind("SUPER + SHIFT + Space", hl.dsp.exec_cmd("qs ipc call launcher open"))
hl.bind("SUPER + Space",         hl.dsp.exec_cmd("qs ipc call launcher openSubmenu Apps"))
hl.bind("SUPER + ALT + Space",   hl.dsp.exec_cmd("qs ipc call launcher openSubmenu System"))
hl.bind("XF86PowerOff",          hl.dsp.exec_cmd("qs ipc call launcher openSubmenu Power"), { locked = true })

-- Apps
hl.bind("SUPER + Return",        hl.dsp.exec_cmd("uwsm -- app kitty"))
hl.bind("SUPER + E",             hl.dsp.exec_cmd("uwsm -- app nautilus"))
hl.bind("SUPER + B",             hl.dsp.exec_cmd("uwsm -- app firefox"))
hl.bind("SUPER + Grave",         hl.dsp.exec_cmd("uwsm -- app code"))


-- Universal copy / paste
hl.bind("SUPER + C",             hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert" }), { desc = "Universal copy" })
hl.bind("SUPER + V",             hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }), { desc = "Universal paste" })

-- Window Controls
hl.bind("SUPER + W",             hl.dsp.window.close())
hl.bind("SUPER + F",             hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + Tab",           hl.dsp.focus({ workspace = "previous" }))
hl.bind("SUPER + S",             hl.dsp.workspace.toggle_special("scratchpad"))

-- Resizing
hl.bind("SUPER + mouse:272",     hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273",     hl.dsp.window.resize(), { mouse = true })

-- Workspaces
for _, dir in ipairs({ "left", "right", "up", "down" }) do
  hl.bind("SUPER + " .. dir,             hl.dsp.focus({ direction = dir }))
  hl.bind("SUPER + SHIFT + " .. dir,     hl.dsp.window.move({ direction = dir }))
end

for ws = 1, 9 do
  hl.bind("SUPER + " .. ws,             hl.dsp.focus({ workspace = ws }))
  hl.bind("SUPER + SHIFT + " .. ws,     hl.dsp.window.move({ workspace = ws }))
end

-- Media / brightness keys
local media = {
  { "XF86AudioRaiseVolume",  "pamixer -i 5" },
  { "XF86AudioLowerVolume",  "pamixer -d 5" },
  { "XF86AudioMute",         "pamixer -t" },
  { "XF86MonBrightnessUp",   "brightnessctl set 5%+" },
  { "XF86MonBrightnessDown", "brightnessctl set 5%-" },
}
for _, b in ipairs(media) do
  hl.bind(b[1], hl.dsp.exec_cmd(b[2]), { locked = true, repeating = true })
end

-- Screenshot
hl.bind("Print", hl.dsp.exec_cmd(
  "mkdir -p ~/Pictures && " ..
  "file=\"$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png\" && " ..
  "grim -g \"$(slurp)\" \"$file\" && printf '%s' \"$file\" | wl-copy"
))

-- Floating panes
-- Managers
local managers = {
  "wallpaper-picker",
  "wifi-manager",
  "bluetooth-manager",
  "performance-monitor",
  "audio-manager",
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
}
for _, name in ipairs(launchers) do
  hl.window_rule({
    match = { title = name },
    float = true,
    center = true,
    size = { 400, 400 },
  })
end

hl.window_rule({
  match = { title = "Select what to share" },
  float = true,
  center = true,
  size = { 800, 600 },
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
