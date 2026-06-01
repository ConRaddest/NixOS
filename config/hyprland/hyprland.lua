local config_dir = os.getenv("HOME") .. "/.local/nos/config/hyprland"

dofile(config_dir .. "/_startup.lua")
dofile(config_dir .. "/monitors.lua")
dofile(config_dir .. "/settings.lua")
dofile(config_dir .. "/animations.lua")
dofile(config_dir .. "/keybindings.lua")
dofile(config_dir .. "/windowrules.lua")
