-- Startup
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("polkit-gnome-authentication-agent")
end)

-- Monitor
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Settings
hl.config({
  input = {
    kb_layout = "za",
    follow_mouse = 1,
    touchpad = { natural_scroll = true },
  },
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 0,
    layout = "dwindle",
  },
  decoration = {
    rounding = 0,
    active_opacity = 0.97,
    inactive_opacity = 0.95,
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
  misc = { disable_hyprland_logo = true },
})

-- Keybinds
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
