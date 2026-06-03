{ ... }:

{
  flake.systemModules.power =
    { pkgs, ... }:

    {
      boot.kernelParams = [ "mem_sleep_default=deep" ];

      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
    };
}
