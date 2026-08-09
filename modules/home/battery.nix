{ ... }:

{
  flake.lib.homeModules.battery =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.brightnessctl ];
    };
}
