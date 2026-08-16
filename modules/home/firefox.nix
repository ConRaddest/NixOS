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

      stylix.targets.firefox.enable = false;

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
          host.firefox.certificatePath != null
        ) host.firefox.certificatePath;
        profiles.default = {
          id = 0;
          isDefault = true;
          path = host.firefox.profilePath;
          settings = {
            "media.webrtc.pipewire.enabled" = true;
            "widget.gtk.libadwaita-colors.enabled" = false;
          };
        };
      };
    };
}
