{
  flake.nixosModules.networking =
    { pkgs, ... }:

    {
      # COSMIC and Plasma use NetworkManager's D-Bus API for their network
      # widgets. NetworkManager owns wireless and wired connections using its
      # default wpa_supplicant Wi-Fi backend.
      networking.networkmanager = {
        enable = true;
        wifi.backend = "wpa_supplicant";
        dns = "systemd-resolved";
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
