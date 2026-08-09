{ ... }:

{
  flake.nixosModules.nvidia =
    { config, lib, ... }:

    let
      prime = config.nos.hardware.nvidiaPrime;
    in
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        open = config.nos.hardware.nvidiaOpen;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        powerManagement.enable = true;
        moduleParams.nvidia.NVreg_TemporaryFilePath = "/var/tmp";
      }
      // lib.optionalAttrs (prime != null) {
        prime = {
          nvidiaBusId = prime.nvidiaBusId;
          offload = {
            enable = prime.offload;
            enableOffloadCmd = prime.offload;
          };
        }
        // lib.optionalAttrs (prime.integratedGpu == "intel") {
          intelBusId = prime.integratedBusId;
        }
        // lib.optionalAttrs (prime.integratedGpu == "amd") {
          amdgpuBusId = prime.integratedBusId;
        };
      };
    };
}
