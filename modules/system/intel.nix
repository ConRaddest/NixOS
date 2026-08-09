{ pkgs, ... }:

{
  flake.nixosModules.intel =
    { ... }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.intel-media-driver ];
        extraPackages32 = [ pkgs.pkgsi686Linux.intel-media-driver ];
      };

      programs.steam.enable = true;
      services.xserver.videoDrivers = [ "modesetting" ];
    };
}
