{ ... }:

{
  flake.lib.homeModules.firefox =
    {
      config,
      inputs,
      pkgs,
      ...
    }:

    let
      firefoxPackage = inputs.firefox-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.firefox;
    in
    {
      home.packages = [ pkgs.mkcert ];

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
        package = firefoxPackage;
        policies.Certificates.Install = [
          "${config.home.homeDirectory}/.local/share/mkcert/rootCA.pem"
        ];
        profiles.default = {
          id = 0;
          isDefault = true;
          path = "td4m60gg.default";
          settings = {
            "media.webrtc.pipewire.enabled" = true;
            "widget.gtk.libadwaita-colors.enabled" = false;
          };
        };
      };
    };
}
