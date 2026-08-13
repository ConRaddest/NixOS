{ ... }:

{
  flake.lib.homeModules.slack =
    { pkgs, ... }:

    let
      slackX11 = pkgs.writeShellApplication {
        name = "slack-x11";
        runtimeInputs = [ pkgs.slack ];
        text = ''
          export NIXOS_OZONE_WL=0
          exec slack --ozone-platform=x11 --disable-features=WebRTCPipeWireCapturer -s "$@"
        '';
      };
    in
    {
      home.packages = [ slackX11 ];

      xdg.desktopEntries.slack = {
        name = "Slack";
        comment = "Slack for desktop";
        exec = "slack-x11 %U";
        icon = "slack";
        type = "Application";
        mimeType = [ "x-scheme-handler/slack" ];
        categories = [
          "Network"
          "InstantMessaging"
        ];
      };

      # Slack does not expose a usable XDG icon in every package version.
      # home.file.".local/share/icons/hicolor/scalable/apps/slack.svg".source = ./slack.svg;
    };
}
