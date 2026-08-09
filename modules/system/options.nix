{ ... }:

{
  flake.nixosModules.options =
    { lib, ... }:
    {
      options.nos = {
        boot = {
          mode = lib.mkOption {
            type = lib.types.enum [
              "uefi"
              "bios"
            ];
            default = "uefi";
            description = "Bootloader mode for this host.";
          };

          device = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "GRUB install device used for BIOS boot.";
          };
        };

        hardware = {
          deepSleep = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to request deep suspend by default.";
          };

          thermald = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to enable Intel thermald.";
          };

          nvidiaOpen = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to use NVIDIA open kernel modules.";
          };

          nvidiaPrime = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  integratedGpu = lib.mkOption {
                    type = lib.types.enum [
                      "intel"
                      "amd"
                    ];
                  };
                  integratedBusId = lib.mkOption { type = lib.types.str; };
                  nvidiaBusId = lib.mkOption { type = lib.types.str; };
                  offload = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                  };
                };
              }
            );
            default = null;
            description = "Optional PRIME configuration for hybrid NVIDIA hosts.";
          };
        };
      };
    };
}
