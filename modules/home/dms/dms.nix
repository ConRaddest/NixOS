{ inputs, ... }:

{
  flake.lib.homeModules.dms =
    { config, ... }:

    {
      imports = [ inputs.dms.homeModules.dank-material-shell ];

      stylix.targets.dank-material-shell.colors.override.withHashtag.base0C =
        config.nos.theme.colors.magenta;

      programs.dank-material-shell = {
        enable = true;
        systemd = {
          enable = true;
          restartIfChanged = true;
        };

        enableDynamicTheming = false;

        # Keep complete snapshots in JSON, but let Stylix own dynamic store paths
        # and values already derived from shared theme config.
        settings = removeAttrs (builtins.fromJSON (builtins.readFile ./settings.json)) [
          "currentThemeName"
          "customThemeFile"
          "popupTransparency"
          "dockTransparency"
          "fontFamily"
          "monoFontFamily"
        ];
        session = removeAttrs (builtins.fromJSON (builtins.readFile ./session.json)) [
          "wallpaperPath"
          "wallpaperPathLight"
          "wallpaperPathDark"
        ];
      };

      systemd.user.services.dms.Service.Environment = [ "QT_QPA_PLATFORMTHEME=qt6ct" ];
    };
}
