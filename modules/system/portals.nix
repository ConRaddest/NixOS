{ ... }:

{
  flake.nixosModules.portals =
    { pkgs, ... }:

    {
      services = {
        gnome.gnome-keyring.enable = true;
        gvfs.enable = true;
        udisks2.enable = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-termfilechooser
        ];

        config.hyprland = {
          default = [
            "gnome"
            "gtk"
          ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
          "org.freedesktop.impl.portal.RemoteDesktop" = [ "hyprland" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };
    };
}
