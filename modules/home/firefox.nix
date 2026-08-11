{ ... }:

{
  flake.lib.homeModules.firefox =
    {
      host,
      lib,
      pkgs,
      ...
    }:

    {
      home.packages = [ pkgs.mkcert ];

      stylix.targets.firefox = {
        profileNames = [ "default" ];
        firefoxGnomeTheme.enable = true;
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
          "x-scheme-handler/slack" = "slack.desktop";
        };
      };

      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        policies.Certificates.Install = lib.optional (
          host.firefoxCertificatePath != null
        ) host.firefoxCertificatePath;
        profiles.default = {
          id = 0;
          isDefault = true;
          path = host.firefoxProfilePath;
          settings = {
            "media.webrtc.pipewire.enabled" = true;
            "widget.gtk.libadwaita-colors.enabled" = false;
          };
        };
      };
    };
}
