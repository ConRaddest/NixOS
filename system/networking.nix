{
  flake.nixosModules.networking =
    { pkgs, ... }:

    {
      # COSMIC and Plasma use NetworkManager's D-Bus API for their network
      # widgets. Keep IWD as the Wi-Fi backend while NetworkManager owns device
      # configuration for both wireless and wired connections.
      networking.networkmanager = {
        enable = true;
        wifi.backend = "iwd";
        dns = "systemd-resolved";
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
