{ ... }:

{
  flake.lib.homeModules.hyprland =
    { config, pkgs, ... }:

    {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false; # UWSM handles the session
      };

      home.packages = [ pkgs.inotify-tools ];

      xdg.configFile."hypr/hyprland.lua".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/nos/config/hyprland/hyprland.lua";
    };
}
