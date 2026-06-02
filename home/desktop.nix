{ ... }:

{
  flake.lib.homeModules.desktop =
    { pkgs, config, ... }:

    {
      home.file.".local/share/chromium-pwas/teams/.keep".text = "";

      xdg.desktopEntries = {
        teams-pwa = {
          name = "Teams";
          genericName = "Teams PWA";
          comment = "Microsoft Teams running as a Chromium web app";
          exec = "${pkgs.chromium}/bin/chromium --user-data-dir=${config.home.homeDirectory}/.local/share/chromium-pwas/teams --class=TeamsPWA --name=Teams --app=https://teams.cloud.microsoft/ --ozone-platform-hint=auto --enable-native-notifications --enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer,NativeNotifications,SystemNotifications %U";
          icon = pkgs.fetchurl {
            url = "https://statics.teams.cdn.office.net/evergreen-assets/icons/microsoft_teams_logo_refresh_v2025.ico";
            sha256 = "0dv0ivb5q9gcymialcyjwdiv00gxl8fcjggnc206lypq10iv2isv";
          };
          terminal = false;
          categories = [
            "Network"
            "Chat"
            "Office"
          ];
          mimeType = [ "x-scheme-handler/msteams" ];
          settings.StartupWMClass = "TeamsPWA";
        };

        uuctl = {
          name = "uuctl";
          exec = "uuctl";
          noDisplay = true;
        };
      };
    };
}
