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
      security.pam.services.greetd.enableGnomeKeyring = true;

      services.dbus.packages = [ pkgs.gcr ];
    };
}
