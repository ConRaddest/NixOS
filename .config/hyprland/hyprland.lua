local config_dir = os.getenv("HOME") .. "/OS/.config/hyprland"

-- Keep this file as the entrypoint loaded by Hyprland.
-- Section files live next to it and are imported from the writable ~/OS repo.
dofile(config_dir .. "/components/_startup.lua")
dofile(config_dir .. "/components/monitors.lua")
dofile(config_dir .. "/components/settings.lua")
dofile(config_dir .. "/components/animations.lua")
dofile(config_dir .. "/components/keybindings.lua")
dofile(config_dir .. "/components/windowrules.lua")
