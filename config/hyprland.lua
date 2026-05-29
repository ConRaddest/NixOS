-- Startup
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("polkit-gnome-authentication-agent")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("qs")
end)

-- Monitor
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

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
    active_opacity = 0.95,
    inactive_opacity = 0.93,
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
  { leaf = "fade",       speed = 4,  bezier = "fast" },
  { leaf = "workspaces", speed = 4,  bezier = "fast" },
}

for _, animation in ipairs(animations) do
  animation.enabled = true
  hl.animation(animation)
end

-- Keybinds
hl.bind("SUPER + Space",         hl.dsp.exec_cmd("qs ipc call launcher open"))
hl.bind("SUPER + Return",        hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + E",             hl.dsp.exec_cmd("nautilus"))
hl.bind("SUPER + W",             hl.dsp.window.close())
hl.bind("SUPER + F",             hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + T",             hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + Tab",           hl.dsp.focus({ workspace = "previous" }))

hl.bind("SUPER + mouse:272",     hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273",     hl.dsp.window.resize(), { mouse = true })

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

-- Floating panes launched from the status bar.
local managers = {
  "wifi-manager",
  "bluetooth-manager",
  "performance-monitor",
}
for _, name in ipairs(managers) do
  hl.window_rule({
    match = { title = name },
    float = true,
    center = true,
    size = { 900, 550 },
  })
end

local launchers = {
  "shell-launcher",
}
for _, name in ipairs(launchers) do
  hl.window_rule({
    match = { title = name },
    float = true,
    center = true,
    size = { 500, 500 },
  })
end

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
