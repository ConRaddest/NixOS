{ ... }:

{
  flake.lib.homeModules.hyprpaper =
    { self, config, ... }:

    let
      theme = import "${self}/themes/current.nix";
      stateDir = "${config.xdg.stateHome}/nos";
      currentWallpaper = "${stateDir}/current-wallpaper";
      defaultWallpaper = "${self}/themes/${theme.id}/wallpapers/${theme.wallpaper}";
    in
    {
      home.activation.ensureCurrentWallpaper = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${stateDir}"

        if [ ! -e "${currentWallpaper}" ]; then
          ln -s "${defaultWallpaper}" "${currentWallpaper}"
        fi
      '';

      services.hyprpaper = {
        enable = true;

        settings = {
          splash = false;

          preload = [
            currentWallpaper
          ];

          wallpaper = [
            {
              monitor = ""; # Empty string applies to all monitors
              path = currentWallpaper;
              fit_mode = "cover";
            }
          ];
        };
      };
    };
}
