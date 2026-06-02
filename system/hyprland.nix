{ ... }:

{
  flake.systemModules.hyprland =
    { pkgs, ... }:

    {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };

      services.gnome.gnome-keyring.enable = true;
      services.dbus.packages = [ pkgs.gcr ];
      security.pam.services.greetd.enableGnomeKeyring = true;
      # Home Manager installs hyprlock, but the PAM service needs to exist at
      # the system level. Without this hyprlock falls back to /etc/pam.d/su.
      security.pam.services.hyprlock = { };

      environment.sessionVariables = {
        GTK_USE_PORTAL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
      };
    };
}
