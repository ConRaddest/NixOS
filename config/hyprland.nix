{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false; # UWSM handles the session
  };

  xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;
}
