{ ... }:

let
  hostName = builtins.baseNameOf (toString ./.);
in
{
  flake.nixosModules."${hostName}Hardware" =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      # Replace these values with output from:
      # sudo nixos-generate-config --show-hardware-config
      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/REPLACE_ROOT_UUID";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/REPLACE_BOOT_UUID";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/REPLACE_SWAP_UUID"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # Add matching CPU microcode configuration when needed:
      # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
