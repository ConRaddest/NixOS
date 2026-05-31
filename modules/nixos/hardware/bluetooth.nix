{ ... }:

{
  flake.nixosModules.bluetooth =
    { pkgs, ... }:

    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      # Unblock bluetooth on system startup.
      systemd.services.bluetooth-unblock = {
        description = "Unblock Bluetooth with rfkill";
        wantedBy = [ "multi-user.target" ];
        after = [ "bluetooth.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
        };
      };
    }
;
}
