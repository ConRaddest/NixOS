local config_dir = os.getenv("HOME") .. "/NixOS/config/hyprland"
-- Startup
hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm app -- hyprpaper")
	hl.exec_cmd("systemctl --user enable --now hyprpolkitagent.service")
	hl.exec_cmd("uwsm app -- qs")
	hl.exec_cmd("uwsm app -- wl-paste --watch cliphist store")
	hl.exec_cmd("uwsm app -- hyprlock")
end)

dofile(config_dir .. "/monitors.lua")
dofile(config_dir .. "/config.lua")
dofile(config_dir .. "/animations.lua")
dofile(config_dir .. "/keybindings.lua")
dofile(config_dir .. "/windowrules.lua")
