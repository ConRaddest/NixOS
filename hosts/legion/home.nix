{ pkgs, ... }:

let
  configDir = "/home/cdt/OS";

  font = {
    name = "Cantarell";
    size = 11;
    mono = "JetBrainsMono Nerd Font";
    monoSize = 10;
  };

  colors = {
    bg       = "#1a1b26";
    bgDark   = "#16161e";
    bgAlt    = "#292e42";

    fg       = "#c0caf5";
    fgDark   = "#a9b1d6";
    fgDim    = "#565f89";

    hover         = "#222637";
    comment       = "#565f89";
    selection     = "#2b2f3a";
    surfaceLight  = "#2a2f43";

    black    = "#414868";
    red      = "#f7768e";
    orange   = "#ff9e64";
    yellow   = "#e0af68";
    green    = "#9ece6a";
    teal     = "#73daca";
    cyan     = "#7dcfff";
    blue     = "#7aa2f7";
    magenta  = "#bb9af7";
    purple   = "#9d7cd8";
  };
in

{
  _module.args = { inherit font colors configDir; };

  imports = [
    ../../.config/firefox/firefox.nix
    ../../.config/theme/theme.nix
    ../../.config/hyprland/hyprland.nix
    ../../.config/hyprlock/hyprlock.nix
    ../../.config/hypridle/hypridle.nix
    ../../.config/hyprpaper/hyprpaper.nix
    ../../.config/kitty/kitty.nix
    ../../.config/ssh/ssh.nix
    ../../.config/btop/btop.nix
    ../../.config/vscode/vscode.nix
    ../../.config/starship/starship.nix
    ../../.config/shell/shell.nix
    ../../.config/windows/windows.nix
  ];

  home.username = "cdt";
  home.homeDirectory = "/home/cdt";
  home.stateVersion = "26.05";

  home.sessionVariables = {
    OS_CONFIG_DIR = configDir;
  };

  programs.home-manager.enable = true;
}
