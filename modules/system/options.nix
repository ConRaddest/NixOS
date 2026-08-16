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
      };
    };
}
