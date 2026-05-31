{ ... }:

{
  flake.lib.homeModules.quickshell =
    { self, config, pkgs, colors, font, ... }:

    let
      stateDir = "${config.xdg.stateHome}/nixos-config";
    in
    {
      home.packages = [ pkgs.quickshell ];

      # The only file Nix generates — injects theme tokens and portable resource/state paths.
      xdg.configFile."quickshell/Theme.qml".text = ''
        import QtQuick

        QtObject {
          readonly property string bg:           "${colors.bg}"
          readonly property string bgAlt:        "${colors.bgAlt}"
          readonly property string fg:           "${colors.fg}"
          readonly property string fgDim:        "${colors.comment}"
          readonly property string accent:       "${colors.blue}"
          readonly property string hover:        "${colors.hover}"
          readonly property string surfaceLight: "${colors.surfaceLight}"
          readonly property string selection:    "${colors.selection}"
          readonly property string monoFont:     "${font.mono}"

          readonly property string flakeDir:     "${self}"
          readonly property string assetDir:     "${self}/assets"
          readonly property string wallpaperDir: "${self}/wallpapers"
          readonly property string stateDir:     "${stateDir}"
        }
      '';

      xdg.configFile."quickshell/shell.qml".source =
        "${self}/assets/shell/shell.qml";

      xdg.configFile."quickshell/components".source =
        "${self}/assets/shell/components";

      xdg.configFile."quickshell/scripts".source =
        "${self}/assets/shell/scripts";

      xdg.configFile."hypr/xdph.conf".text = ''
        screencopy {
          custom_picker_binary = ${self}/assets/shell/scripts/screenshare.sh
        }
      '';
    }
;
}
