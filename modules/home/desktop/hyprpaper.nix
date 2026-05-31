{ ... }:

{
  flake.lib.homeModules.hyprpaper =
    { self, config, ... }:

    let
      stateDir = "${config.xdg.stateHome}/nixos-config";
      currentWallpaper = "${stateDir}/current-wallpaper";
      defaultWallpaper = "${self}/wallpapers/sunset-lake.png";
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
    }
;
}
