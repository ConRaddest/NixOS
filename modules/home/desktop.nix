{ ... }:

{
  flake.lib.homeModules.desktop =
    {
      host,
      lib,
      pkgs,
      ...
    }:

    let
      slackX11 = pkgs.writeShellApplication {
        name = "slack-x11";
        runtimeInputs = [ pkgs.slack ];
        text = ''
          export NIXOS_OZONE_WL=0
          exec slack --ozone-platform=x11 --disable-features=WebRTCPipeWireCapturer -s "$@"
        '';
      };

      steamLauncher = pkgs.writeShellApplication {
        name = "steam-launcher";
        runtimeInputs = [ pkgs.steam ];
        text = ''
          # DMS runs as a Qt systemd service. Do not leak its Qt/Wayland
          # environment into Steam's older X11 UI and embedded browser.
          unset NIXOS_OZONE_WL QT_PLUGIN_PATH QT_QPA_PLATFORM
          unset QT_QPA_PLATFORMTHEME QT_QPA_PLATFORMTHEME_QT6
          export GDK_BACKEND=x11
          exec steam "$@"
        '';
      };
    in
    {
      home.packages = [ slackX11 ] ++ lib.optional host.gaming steamLauncher;

      # Hide upstream entries that have NoDisplay=true but still surface in launchers.
      xdg.desktopEntries.uuctl = {
        name = "uuctl";
        exec = "uuctl";
        noDisplay = true;
        type = "Application";
      };

      xdg.desktopEntries.steam = lib.mkIf host.gaming {
        name = "Steam";
        comment = "Application for managing and playing games on Steam";
        exec = "steam-launcher %U";
        icon = "steam";
        type = "Application";
        mimeType = [
          "x-scheme-handler/steam"
          "x-scheme-handler/steamlink"
        ];
        categories = [
          "Network"
          "FileTransfer"
          "Game"
        ];
      };

      xdg.desktopEntries.slack = {
        name = "Slack";
        comment = "Slack Desktop";
        exec = "slack-x11 %U";
        icon = "slack";
        type = "Application";
        mimeType = [ "x-scheme-handler/slack" ];
        categories = [
          "Network"
          "InstantMessaging"
        ];
      };

      xdg.desktopEntries.teams-for-linux = {
        name = "Teams for Linux";
        comment = "Unofficial Microsoft Teams client";
        exec = "teams-for-linux --disable-gpu %U";
        icon = "teams-for-linux";
        type = "Application";
        mimeType = [ "x-scheme-handler/msteams" ];
        categories = [
          "Network"
          "InstantMessaging"
        ];
      };

      # Custom icons for apps that don't ship XDG icons.
      # Drop SVGs into hicolor so any icon name reference resolves automatically.
      home.file = {
        # --- Slack ---
        ".local/share/icons/hicolor/scalable/apps/slack.svg".text = ''
          <svg enable-background="new 0 0 2447.6 2452.5" viewBox="0 0 2447.6 2452.5" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m897.4 0c-135.3.1-244.8 109.9-244.7 245.2-.1 135.3 109.5 245.1 244.8 245.2h244.8v-245.1c.1-135.3-109.5-245.1-244.9-245.3.1 0 .1 0 0 0m0 654h-652.6c-135.3.1-244.9 109.9-244.8 245.2-.2 135.3 109.4 245.1 244.7 245.3h652.7c135.3-.1 244.9-109.9 244.8-245.2.1-135.4-109.5-245.2-244.8-245.3z" fill="#36c5f0"/><path d="m2447.6 899.2c.1-135.3-109.5-245.1-244.8-245.2-135.3.1-244.9 109.9-244.8 245.2v245.3h244.8c135.3-.1 244.9-109.9 244.8-245.3zm-652.7 0v-654c.1-135.2-109.4-245-244.7-245.2-135.3.1-244.9 109.9-244.8 245.2v654c-.2 135.3 109.4 245.1 244.7 245.3 135.3-.1 244.9-109.9 244.8-245.3z" fill="#2eb67d"/><path d="m1550.1 2452.5c135.3-.1 244.9-109.9 244.8-245.2.1-135.3-109.5-245.1-244.8-245.2h-244.8v245.2c-.1 135.2 109.5 245 244.8 245.2zm0-654.1h652.7c135.3-.1 244.9-109.9 244.8-245.2.2-135.3-109.4-245.1-244.7-245.3h-652.7c-135.3.1-244.9 109.9-244.8 245.2-.1 135.4 109.4 245.2 244.7 245.3z" fill="#ecb22e"/><path d="m0 1553.2c-.1 135.3 109.5 245.1 244.8 245.2 135.3-.1 244.9-109.9 244.8-245.2v-245.2h-244.8c-135.3.1-244.9 109.9-244.8 245.2zm652.7 0v654c-.2 135.3 109.4 245.1 244.7 245.3 135.3-.1 244.9-109.9 244.8-245.2v-653.9c.2-135.3-109.4-245.1-244.7-245.3-135.4 0-244.9 109.8-244.8 245.1 0 0 0 .1 0 0" fill="#e01e5a"/></g></svg>
        '';
      };
    };
}
