require("nix.colors")
require("nix.theme")
pcall(require, "nix.input")

require("config.settings")
require("config.animations")
require("config.window_rules")
require("config.monitors")
require("config.keybindings")
pcall(require, "nix.voxtype")

require("nix.shell").setup()
