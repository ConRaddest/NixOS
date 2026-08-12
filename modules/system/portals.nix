{ ... }:

{
  flake.nixosModules.portals =
    { pkgs, ... }:

    {
      services.gvfs.enable = true;
      services.udisks2.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-termfilechooser
        ];

        config.common = {
          default = [
            "hyprland"
            "gtk"
          ];

          "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
          "org.freedesktop.impl.portal.RemoteDesktop" = [ "hyprland" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
        };
      };
    };
}
