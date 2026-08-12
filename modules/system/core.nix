{ ... }:

{
  flake.nixosModules.core =
    {
      host,
      lib,
      pkgs,
      ...
    }:

    {
      # Hide noisy early kernel/firmware warnings from the TTY while still
      # showing systemd boot progress. Warnings remain available in journalctl/dmesg.
      boot = {
        consoleLogLevel = 0;
        initrd = {
          verbose = false;
        };
        kernelParams = [
          "quiet"
          "loglevel=0"
          "udev.log_level=3"
          "systemd.show_status=true"
        ];
      };

      fileSystems = builtins.listToAttrs (
        map (mount: {
          name = mount.mountPoint;
          value = {
            inherit (mount) device fsType;
            options = mount.options or [ ];
          };
        }) (host.mounts or [ ])
      );

      assertions = map (mount: {
        assertion = lib.hasPrefix "/" mount.mountPoint;
        message = "Host mount point must be an absolute path: ${mount.mountPoint}";
      }) (host.mounts or [ ]);

      # Desktop processes such as Electron can expose multi-gigabyte virtual
      # mappings. Processing their crashes as core dumps can saturate disk I/O
      # and freeze graphical session for minutes.
      systemd.coredump.settings.Coredump = {
        Storage = "none";
        ProcessSizeMax = 0;
      };

      services.fstrim.enable = true;
      services.fwupd.enable = true;

      environment.systemPackages = with pkgs; [
        pciutils
        usbutils
      ];
    };
}
