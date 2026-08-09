{ ... }:

{
  flake.nixosModules.core =
    { pkgs, ... }:

    {
      # Hide noisy early kernel/firmware warnings from the TTY while still
      # showing systemd boot progress. Warnings remain available in journalctl/dmesg.
      boot.consoleLogLevel = 0;
      boot.initrd.verbose = false;
      boot.kernelParams = [
        "quiet"
        "loglevel=0"
        "udev.log_level=3"
        "systemd.show_status=true"
      ];

      environment.systemPackages = with pkgs; [
        pciutils
        usbutils
      ];
    };
}
