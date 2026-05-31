{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Required for Dockerized QEMU/Windows acceleration and networking.
  boot.kernelModules = [ "kvm-intel" "tun" ];

  # Intel Wireless-AC 9560 stability: avoid Wi-Fi power saving disconnects.
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0 uapsd_disable=1
  '';
}
