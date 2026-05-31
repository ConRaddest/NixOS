{
  flake.nixosModules.networking =
    { pkgs, ... }:

    {
      # Use iwd directly, managed from impala/iwctl. Do not run NetworkManager at
      # the same time, otherwise NM and impala/iwd can fight over reconnects.
      networking.networkmanager.enable = false;
      networking.useDHCP = false;

      networking.wireless.iwd = {
        enable = true;
        settings = {
          Settings.AutoConnect = true;
          General.EnableNetworkConfiguration = true;
          Network = {
            EnableIPv6 = true;
            NameResolvingService = "systemd";
          };
        };
      };

      # DNS for iwd's built-in network configuration.
      services.resolved.enable = true;

      # Disable WiFi power management — the driver was sending deauth (reason 4,
      # from_ap: false) every few minutes, causing periodic disconnects.
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev %k set power_save off"
      '';
    }
;
}
