{
  flake.nixosModules.networking =
    { host, ... }:

    {
      # COSMIC and Plasma use NetworkManager's D-Bus API for their network
      # widgets. NetworkManager owns wireless and wired connections using its
      # default wpa_supplicant Wi-Fi backend.
      networking.networkmanager = {
        enable = true;
        wifi.backend = "wpa_supplicant";
        dns = "systemd-resolved";
      };

      # LocalSend discovery and file transfers.
      networking.firewall = {
        allowedTCPPorts = [ 53317 ];
        allowedUDPPorts = [ 53317 ];
      };

      services.resolved = {
        enable = true;
        settings.Resolve.FallbackDNS = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };

      # Custom local hosts for development (defined per host)
      networking.hosts = {
        "127.0.0.1" = host.localHosts;
        "::1" = host.localHosts;
      };
    };
}
