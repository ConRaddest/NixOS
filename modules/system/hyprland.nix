{ ... }:

{
  flake.nixosModules.hyprland =
    { ... }:

    {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };
    };
}
