{ ... }:

{
  flake.nixosModules.intel =
    { pkgs, ... }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.intel-media-driver ];
        extraPackages32 = [ pkgs.pkgsi686Linux.intel-media-driver ];
      };

      services.xserver.videoDrivers = [ "modesetting" ];
    };
}
