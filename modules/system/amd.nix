{ ... }:

{
  flake.nixosModules.amd =
    { ... }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      services.xserver.videoDrivers = [ "amdgpu" ];

      hardware.amdgpu.initrd.enable = true;
    };
}
