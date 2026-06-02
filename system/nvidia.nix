{ ... }:

{
  flake.systemModules.nvidia =
    { config, ... }:

    {
      hardware.graphics.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        open = false;
        package = config.boot.kernelPackages.nvidiaPackages.stable;

        # Use NVIDIA's systemd suspend/resume hooks and preserve VRAM across
        # sleep. Without this, Wayland sessions can resume to broken rendering,
        # black windows, or crashed GPU clients.
        powerManagement.enable = true;

        # PreserveVideoMemoryAllocations stores VRAM contents while suspended.
        # Keep that backing store on persistent disk space instead of /tmp.
        moduleParams.nvidia.NVreg_TemporaryFilePath = "/var/tmp";
      };
    };
}
