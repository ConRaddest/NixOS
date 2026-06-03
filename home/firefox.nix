{ ... }:

{
  flake.lib.homeModules.firefox =
    { pkgs, lib, ... }:

    {
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
        };
      };

      programs.firefox = {
        enable = true;
        policies.Certificates.Install = [
          "/home/cdt/.local/share/mkcert/rootCA.pem"
        ];
        profiles.default = {
          id = 0;
          isDefault = true;
          path = "td4m60gg.default";
          settings = {
            "media.webrtc.pipewire.enabled" = true;
          };
        };
      };
    };
}
