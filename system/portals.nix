{ ... }:

{
  flake.systemModules.portals =
    { pkgs, ... }:

    {
      # Nautilus/GIO trash, metadata, and volume integration.
      services.gvfs.enable = true;
      services.udisks2.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-hyprland
        ];
        config.common.default = [
          "hyprland"
          "gtk"
        ];
        config.common."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        config.common."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
}
