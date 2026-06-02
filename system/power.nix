{ ... }:

{
  flake.systemModules.power =
    { ... }:

    {
      # This laptop advertises both s2idle and deep suspend, but deep/S3 is
      # currently triggering NVIDIA resume failures on this machine. Prefer
      # s2idle for reliable wake until the driver/firmware combination behaves.
      boot.kernelParams = [ "mem_sleep_default=s2idle" ];

      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
    };
}
