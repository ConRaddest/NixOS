{ ... }:

{
  flake.lib.homeModules.bluetooth =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bluetui ];
    };
}
