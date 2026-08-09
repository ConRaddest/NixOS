{ ... }:

{
  flake.nixosModules.amd =
    { ... }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      programs.steam.enable = true;
      services.xserver.videoDrivers = [ "amdgpu" ];

      hardware.amdgpu.initrd.enable = true;
    };
}
