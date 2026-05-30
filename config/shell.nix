{ config, pkgs, colors, font, ... }:

{
  home.packages = [ pkgs.quickshell ];

  # The only file Nix generates — injects color and font tokens from home.nix.
  # Everything else in OS/quickshell/ is a plain editable file.
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
    }
  '';

  # All quickshell source files live in OS/quickshell/ and are symlinked here.
  xdg.configFile."quickshell/shell.qml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/OS/config/shell.qml";
  };

  xdg.configFile."quickshell/components" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/OS/quickshell";
    recursive = true;
  };

  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      custom_picker_binary = ${config.home.homeDirectory}/OS/quickshell/screenshare.sh
    }
  '';
}
