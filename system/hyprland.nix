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
    };
}
