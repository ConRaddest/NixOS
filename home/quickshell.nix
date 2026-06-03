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
          readonly property string bgDark:       "${colors.bgDark}"
          readonly property string bgLight:      "${colors.bgLight}"

          readonly property string fg:           "${colors.fg}"
          readonly property string fgDark:       "${colors.fgDark}"
          readonly property string fgLight:      "${colors.fgLight}"

          readonly property string primary:      "${colors.primary}"
          readonly property string secondary:    "${colors.secondary}"
          readonly property string tertiary:     "${colors.tertiary}"
          readonly property string quaternary:   "${colors.quaternary}"

          readonly property string black:        "${colors.black}"
          readonly property string red:          "${colors.red}"
          readonly property string orange:       "${colors.orange}"
          readonly property string yellow:       "${colors.yellow}"
          readonly property string green:        "${colors.green}"
          readonly property string teal:         "${colors.teal}"
          readonly property string blue:         "${colors.blue}"
          readonly property string purple:       "${colors.purple}"

          readonly property string monoFont:     "${font.mono}"

          readonly property string flakeDir:     "${nos}"
          readonly property string assetDir:     "${nos}"
          readonly property string wallpaperDir: "${nos}/themes/${theme.id}/wallpapers"
          readonly property string themeDir:     "${nos}/themes"
          readonly property string stateDir:     "${stateDir}"
        }
      '';

      xdg.configFile."quickshell/shell.qml".source = sym "${nos}/config/quickshell/shell.qml";
      xdg.configFile."quickshell/components".source = sym "${nos}/config/quickshell/components";
      xdg.configFile."quickshell/scripts".source = sym "${nos}/scripts";

      xdg.configFile."hypr/xdph.conf".text = ''
        screencopy {
          custom_picker_binary = ${nos}/scripts/shell/screen.sh
        }
      '';
    };
}
