{ ... }:

{
  flake.systemModules.legionHardware =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      
      boot.kernelModules = [
        "kvm-intel" # Intel VT-x for virtualisation
        "tun" # virtual network interfaces for Docker/VMs
      ];

      boot.extraModulePackages = [ ];

      # Intel Wireless-AC 9560 (CNVi) stability fixes.
      # power_save=0 + power_scheme=1: disable all firmware power saving (CAM mode).
      # bt_coex_active=0: disable WiFi/BT coexistence — the BT keyboard sharing the
      # same radio was causing mac80211's keep-alive monitor to time out.
      boot.extraModprobeConfig = ''
        options iwlwifi power_save=0 uapsd_disable=1 bt_coex_active=0
        options iwlmvm power_scheme=1
      '';

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/fb1d081a-2de5-49ba-a19f-2df4274e9a90";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/4B9E-C95A";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/2a076ad6-8875-49d8-81d0-0e654f2bee46"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
