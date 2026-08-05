{ ... }:

{
  flake.nixosModules.nvidia =
    { config, ... }:

    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
      programs.steam.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        open = false;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        powerManagement.enable = true;
        moduleParams.nvidia.NVreg_TemporaryFilePath = "/var/tmp";
      };
    };
}
