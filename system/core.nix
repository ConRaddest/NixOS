{ ... }:

{
  flake.nixosModules.core =
    { pkgs, ... }:

    {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

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

      # Larger virtual-console/TTY font, roughly 1.5x the default 16px size.
      console.packages = [ pkgs.terminus_font ];
      console.font = "ter-v24n";
      console.earlySetup = true;

      environment.systemPackages = with pkgs; [
        pciutils
        usbutils
      ];
    };
}
