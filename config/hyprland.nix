{ config, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false; # UWSM handles the session
  };

  xdg.configFile."hypr/hyprland.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/OS/config/hyprland.lua";
}
