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

      home.activation.mkcertFirefox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cert="$HOME/.local/share/mkcert/rootCA.pem"
        ini="$HOME/.mozilla/firefox/profiles.ini"
        if [ -f "$cert" ] && [ -f "$ini" ]; then
          profile=$(grep -A1 "Default=1" "$ini" | grep "^Path=" | cut -d= -f2)
          if [ -n "$profile" ]; then
            ${pkgs.nss}/bin/certutil -A -n "mkcert local CA" -t "CT,," \
              -i "$cert" -d "sql:$HOME/.mozilla/firefox/$profile" 2>/dev/null || true
          fi
        fi
      '';

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
