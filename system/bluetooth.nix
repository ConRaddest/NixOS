{ ... }:

{
  flake.systemModules.bluetooth =
    { pkgs, ... }:

    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
    };
}
