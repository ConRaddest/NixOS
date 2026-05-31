{ config, pkgs, colors, font, configDir, ... }:

{
  home.packages = [ pkgs.quickshell ];

  # The only file Nix generates — injects color, font, and config path tokens from home.nix.
  # Everything else in the config repo is a plain editable file.
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
      readonly property string configDir:    "${configDir}"
    }
  '';

  # All quickshell source files live in the config repo and are symlinked here.
  xdg.configFile."quickshell/shell.qml" = {
    source = config.lib.file.mkOutOfStoreSymlink "${configDir}/.config/shell/shell.qml";
  };

  xdg.configFile."quickshell/components" = {
    source = config.lib.file.mkOutOfStoreSymlink "${configDir}/.config/shell/components";
    recursive = true;
  };

  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      custom_picker_binary = ${configDir}/.config/shell/scripts/screenshare.sh
    }
  '';
}
