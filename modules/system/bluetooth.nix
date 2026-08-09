{ ... }:

{
  flake.nixosModules.bluetooth =
    { pkgs, ... }:

    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      # systemd-rfkill can persist a previous soft-blocked Bluetooth state.
      # Force-unblock the controller before bluetoothd starts so powerOnBoot can
      # reliably turn it on after rebuilds/reboots.
      systemd.services.bluetooth-unblock = {
        description = "Unblock Bluetooth rfkill before bluetoothd starts";
        wantedBy = [ "multi-user.target" ];
        before = [ "bluetooth.service" ];
        after = [ "systemd-rfkill.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
        };
      };

    };
}
