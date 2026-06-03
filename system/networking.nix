{
  flake.systemModules.networking =
    { ... }:

    {
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
