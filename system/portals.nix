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
        # Screen/window sharing must be handled by the Hyprland portal on Wayland.
        # Being explicit avoids xdg-desktop-portal falling back to gtk for apps
        # such as Firefox/Teams after a failed portal request.
        config.common."org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        config.common."org.freedesktop.impl.portal.RemoteDesktop" = [ "hyprland" ];
        config.common."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        config.common."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
}
