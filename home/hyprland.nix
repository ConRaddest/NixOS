{ ... }:

{
  flake.lib.homeModules.hyprland =
    { config, pkgs, ... }:

    {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false;
      };

      xdg.configFile."hypr/hyprland.lua".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/config/hyprland/hyprland.lua";
    };
}
