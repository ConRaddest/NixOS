{
  flake.nixosModules.networking =
    { pkgs, ... }:

    {
      networking.networkmanager.enable = false;
      networking.useDHCP = false;

      # IWD manages Wi-Fi; systemd-networkd handles wired LAN DHCP.
      systemd.network = {
        enable = true;
        wait-online.enable = false;
        networks."20-wired" = {
          matchConfig.Name = "en*";
          networkConfig = {
            DHCP = "yes";
            IPv6AcceptRA = true;
          };
        };
      };

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

      environment.systemPackages = with pkgs; [
        impala
        iwd
      ];

      services.resolved = {
        enable = true;
        settings.Resolve.FallbackDNS = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };

      networking.hosts = {
        "127.0.0.1" = [
          "management-local.pmis.servicesseta.org.za"
          "partner-local.pmis.servicesseta.org.za"
          "learner-local.pmis.servicesseta.org.za"
        ];
        "::1" = [
          "management-local.pmis.servicesseta.org.za"
          "partner-local.pmis.servicesseta.org.za"
          "learner-local.pmis.servicesseta.org.za"
        ];
      };
    };
}
