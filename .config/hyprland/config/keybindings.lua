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

-- WM

-- Universal cut / copy / paste
local pressed_shortcuts = {}

local function send_shortcut_once(mods, key)
  -- Avoid hl.dsp.send_shortcut here: it can leave synthetic keys pressed in
  -- some clients. Send an explicit press and release instead.
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 25, type = "oneshot" })
end

local function bind_shortcut_once(bind, mods, key, desc)
  hl.bind(bind, function()
    if pressed_shortcuts[bind] then return end
    pressed_shortcuts[bind] = true
    send_shortcut_once(mods, key)
  end, { desc = desc })

  hl.bind(bind, function()
    pressed_shortcuts[bind] = false
  end, { release = true })
end

bind_shortcut_once("SUPER + X", "SHIFT", "Delete", "Universal cut")
bind_shortcut_once("SUPER + C", "CTRL",  "Insert", "Universal copy")
bind_shortcut_once("SUPER + V", "SHIFT", "Insert", "Universal paste")

-- Window Controls
hl.bind("SUPER + W",            hl.dsp.window.close())
hl.bind("SUPER + J",            hl.dsp.layout("togglesplit"))
hl.bind("SUPER + T",            hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F",            hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + Tab",          hl.dsp.focus({ workspace = "previous" }))
hl.bind("SUPER + S",            hl.dsp.workspace.toggle_special("scratchpad"))

-- Resizing
hl.bind("SUPER + mouse:272",    hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273",    hl.dsp.window.resize(), { mouse = true })

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

-- NixOS
local function nos_terminal(klass, cmd)
  return hl.dsp.exec_cmd(
    "uwsm app -- kitty --class " .. klass .. " --title " .. klass .. " -e bash -lic '" .. cmd .. "; echo; read -rp \"Press Enter to close...\"'"
  )
end

hl.bind("CTRL + SHIFT + R", nos_terminal("nixos-refresh", "nos-refresh"))
hl.bind("CTRL + SHIFT + B", nos_terminal("nixos-build",   "nos-build"))
hl.bind("CTRL + SHIFT + U", nos_terminal("nixos-update",  "nos-update"))

-- Screenshot
hl.bind("Print", hl.dsp.exec_cmd(
  "mkdir -p ~/Pictures && " ..
  "file=\"$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png\" && " ..
  "grim -g \"$(slurp)\" \"$file\" && printf '%s' \"$file\" | wl-copy"
))
