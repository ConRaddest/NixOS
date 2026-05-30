local config_dir = os.getenv("HOME") .. "/OS/.config/hyprland"

-- Keep this file as the entrypoint loaded by Hyprland.
-- Section files live next to it and are imported from the writable ~/OS repo.
dofile(config_dir .. "/config/_startup.lua")
dofile(config_dir .. "/config/monitors.lua")
dofile(config_dir .. "/config/settings.lua")
dofile(config_dir .. "/config/animations.lua")
dofile(config_dir .. "/config/keybindings.lua")
dofile(config_dir .. "/config/windowrules.lua")

