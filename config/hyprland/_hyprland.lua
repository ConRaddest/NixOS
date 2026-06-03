local config_dir = os.getenv("HOME") .. "/NixOS/config/hyprland"
-- Startup
local startup_apps = {
	"uwsm app -- hyprlock", -- lock the screen after auto-login
	"uwsm app -- hyprpaper", -- load the wallpaper
	"uwsm app -- qs", -- load quickshell
	"systemctl --user enable --now hyprpolkitagent.service", -- load polkitagent
}

hl.on("hyprland.start", function()
	for _, cmd in ipairs(startup_apps) do
		hl.exec_cmd(cmd)
	end
end)

dofile(config_dir .. "/monitors.lua")
dofile(config_dir .. "/config.lua")
dofile(config_dir .. "/animations.lua")
dofile(config_dir .. "/keybindings.lua")
dofile(config_dir .. "/windowrules.lua")
