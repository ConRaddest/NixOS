local repo_dir = os.getenv("OS_CONFIG_DIR")
local config_dir = repo_dir .. "/.config/hyprland"

-- Development entrypoint. The active ~/.config/hypr/hyprland.lua is generated
-- by home-manager from configDir so Hyprland startup does not depend on env vars.
dofile(config_dir .. "/config/_startup.lua")
dofile(config_dir .. "/config/monitors.lua")
dofile(config_dir .. "/config/settings.lua")
dofile(config_dir .. "/config/animations.lua")
dofile(config_dir .. "/config/keybindings.lua")
dofile(config_dir .. "/config/windowrules.lua")

