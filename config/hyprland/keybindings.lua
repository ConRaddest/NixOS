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

-- Universal cut / copy / paste
local universal_shortcut_pressed = {}

local function send_shortcut_once(mods, key)
  -- Clear any stale synthetic state, then send a short, real-looking tap.
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 90, type = "oneshot" })
end

local function bind_universal_shortcut(bind, mods, key, desc)
  hl.bind(bind, function()
    if universal_shortcut_pressed[bind] then return end
    universal_shortcut_pressed[bind] = true
    send_shortcut_once(mods, key)

    -- Safety reset in case Hyprland misses the release event during focus churn.
    hl.timer(function()
      universal_shortcut_pressed[bind] = false
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 1200, type = "oneshot" })
  end, { desc = desc })

  hl.bind(bind, function()
    universal_shortcut_pressed[bind] = false
  end, { release = true })
end

bind_universal_shortcut("SUPER + X", "SHIFT", "Delete", "Universal cut")
bind_universal_shortcut("SUPER + C", "CTRL",  "Insert", "Universal copy")
bind_universal_shortcut("SUPER + V", "SHIFT", "Insert", "Universal paste")

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

-- Laptop switches for managing integrated display safely
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = true })
end, { locked = true })

hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = false })
end, { locked = true })

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
local osd = os.getenv("HOME") .. "/NixOS/config/shell/scripts/osd.sh"

local media = {
  { "XF86AudioRaiseVolume",  "bash " .. osd .. " volume up" },
  { "XF86AudioLowerVolume",  "bash " .. osd .. " volume down" },
  { "XF86AudioMute",         "bash " .. osd .. " volume mute" },
  { "XF86AudioMicMute",      "bash " .. osd .. " mic mute" },
  { "XF86MonBrightnessUp",   "bash " .. osd .. " brightness up" },
  { "XF86MonBrightnessDown", "bash " .. osd .. " brightness down" },
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
  "mkdir -p ~/Screenshots && " ..
  "file=\"$HOME/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png\" && " ..
  "grim -g \"$(slurp)\" \"$file\" && wl-copy --type image/png < \"$file\""
))
