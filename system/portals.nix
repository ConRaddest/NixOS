{ ... }:

{
  flake.systemModules.portals =
    { pkgs, lib, ... }:

    {
      services.gvfs.enable = true;
      services.udisks2.enable = true;

      security.wrappers.xdg-desktop-portal = {
        source = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
        capabilities = "cap_sys_ptrace+eip";
        owner = "root";
        group = "root";
      };

      systemd.user.services.xdg-desktop-portal.serviceConfig.ExecStart = lib.mkForce [
        ""
        "/run/wrappers/bin/xdg-desktop-portal"
      ];

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-termfilechooser
        ];

        config.common.default = [
          "hyprland"
          "gtk"
        ];

        config.common."org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        config.common."org.freedesktop.impl.portal.RemoteDesktop" = [ "hyprland" ];
        config.common."org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
        # config.common."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
}
