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
          export GDK_BACKEND=x11
          exec steam "$@"
        '';
      };
    in
    lib.mkIf host.steam.enable {
      home.packages = [ steamLauncher ];

      xdg.desktopEntries.steam = {
        name = "Steam";
        comment = "Application for managing and playing games";
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
