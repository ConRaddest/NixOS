{ ... }:

let
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
    comment  = "#565f89";
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
  _module.args = { inherit font colors; };

  imports = [
    ./config/theme.nix
    ./config/hyprland.nix
    ./config/hyprlock.nix
    ./config/hypridle.nix
    ./config/hyprpaper.nix
    ./config/kitty.nix
    ./config/btop.nix
    ./config/yazi.nix
    ./config/vscode.nix
    ./config/starship.nix
  ];

  home.username = "cdt";
  home.homeDirectory = "/home/cdt";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
