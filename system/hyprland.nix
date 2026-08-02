{ ... }:

{
  flake.nixosModules.hyprland =
    { pkgs, ... }:

    {
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
      };
    };
}
