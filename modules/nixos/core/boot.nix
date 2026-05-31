{ ... }:

{
  flake.nixosModules.boot =
    { ... }:

    {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Required for Dockerized QEMU/Windows acceleration and networking.
      boot.kernelModules = [ "kvm-intel" "tun" ];

      # Intel CNVi WiFi stability: disable all firmware-level power saving.
      # power_save=0 disables nl80211 power save; power_scheme=1 sets iwlmvm to
      # CAM (Continuously Awake Mode), preventing the firmware from power-cycling
      # and sending deauth frames (reason 4, from_ap: false).
      boot.extraModprobeConfig = ''
        options iwlwifi power_save=0 uapsd_disable=1
        options iwlmvm power_scheme=1
      '';
    }
;
}
