{
  flake.nixosModules.networking =
    { host, ... }:

    {
      # COSMIC and Plasma use NetworkManager's D-Bus API for their network
      # widgets. NetworkManager owns wireless and wired connections using its
      # default wpa_supplicant Wi-Fi backend.
      networking = {
        firewall = {
          allowedTCPPorts = [ 53317 ];
          allowedUDPPorts = [ 53317 ];
        };
        hosts = {
          "127.0.0.1" = host.localHosts;
          "::1" = host.localHosts;
        };
        networkmanager = {
          dns = "systemd-resolved";
          enable = true;
          wifi = {
            backend = "wpa_supplicant";
            # Intel Wi-Fi previously deauthenticated every few minutes with
            # power saving enabled. Keep this in NetworkManager, which owns Wi-Fi.
            powersave = false;
          };
        };
      };

      services.resolved = {
        enable = true;
        settings.Resolve = {
          # Router DNS can stop answering while existing connections remain up.
          # Route all DNS through these servers instead of only using them when
          # DHCP supplies no DNS server.
          DNS = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          Domains = [ "~." ];
          FallbackDNS = [
            "1.0.0.1"
            "8.8.4.4"
          ];
        };
      };
    };
}
