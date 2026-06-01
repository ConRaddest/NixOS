{ ... }:

{
  flake.lib.homeModules.quickshell =
    {
      config,
      pkgs,
      self,
      colors,
      font,
      ...
    }:

    let
      nos = "${config.home.homeDirectory}/NixOS";
      theme = import "${self}/themes/current.nix";
      stateDir = "${config.xdg.stateHome}/nos";
      sym = config.lib.file.mkOutOfStoreSymlink;
    in
    {
      home.packages = [ pkgs.quickshell ];

      # The only file Nix generates — injects theme tokens that can't be known at edit time.
      xdg.configFile."quickshell/Theme.qml".text = ''
        import QtQuick

        QtObject {
          readonly property string bg:           "${colors.bg}"
          readonly property string bgElevated:   "${colors.bgElevated}"
          readonly property string fg:           "${colors.fg}"
          readonly property string fgSubtle:     "${colors.fgSubtle}"
          readonly property string accent:       "${colors.blue}"
          readonly property string hover:        "${colors.hover}"
          readonly property string surface:      "${colors.surface}"
          readonly property string selection:    "${colors.selection}"
          readonly property string monoFont:     "${font.mono}"

          readonly property string flakeDir:     "${nos}"
          readonly property string assetDir:     "${nos}/config"
          readonly property string wallpaperDir: "${nos}/themes/${theme.id}/wallpapers"
          readonly property string themeDir:     "${nos}/themes"
          readonly property string stateDir:     "${stateDir}"
        }
      '';

      xdg.configFile."quickshell/shell.qml".source = sym "${nos}/config/shell/shell.qml";
      xdg.configFile."quickshell/components".source = sym "${nos}/config/shell/components";
      xdg.configFile."quickshell/scripts".source = sym "${nos}/config/shell/scripts";

      xdg.configFile."hypr/xdph.conf".text = ''
        screencopy {
          custom_picker_binary = ${nos}/config/shell/scripts/screenshare.sh
        }
      '';
    };
}
