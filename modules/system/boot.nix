{ ... }:

{
  flake.nixosModules.boot =
    { config, lib, ... }:

    let
      cfg = config.nos.boot;
    in
    {
      config = lib.mkMerge [
        (lib.mkIf (cfg.mode == "uefi") {
          boot.loader.systemd-boot = {
            enable = true;
            configurationLimit = 15;
          };
          boot.loader.efi.canTouchEfiVariables = true;
        })

        (lib.mkIf (cfg.mode == "bios") {
          assertions = [
            {
              assertion = cfg.device != null;
              message = "nos.boot.device must be set when nos.boot.mode is bios.";
            }
          ];

          boot.loader.grub = {
            enable = true;
            device = cfg.device;
          };
        })
      ];
    };
}
