{ ... }:

{
  flake.nixosModules.hyprland =
    { pkgs, username, ... }:

    {
      # Boot lands in the same graphical lock path as resume, while rescue
      # consoles stay available on Ctrl+Alt+F2/F3/etc.
      services.getty = {
        autologinUser = username;
        autologinOnce = true;
      };

      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };

      environment.systemPackages = with pkgs; [
        cliphist
        grim
        hyprpicker
        hyprpolkitagent
        slurp
        wl-clipboard
      ];

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
