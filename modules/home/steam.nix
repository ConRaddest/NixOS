{ ... }:

{
  flake.lib.homeModules.steam =
    {
      host,
      lib,
      pkgs,
      ...
    }:

    let
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
    lib.mkIf host.steam.enable {
      home.packages = [ steamLauncher ];

      xdg.desktopEntries.steam = {
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
    };
}
