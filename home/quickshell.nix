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
      home.packages = with pkgs; [
        libnotify
        python3
        quickshell
      ];

      # The only file Nix generates — injects theme tokens that can't be known at edit time.
      xdg.configFile."quickshell/Theme.qml".text = ''
        import QtQuick

        QtObject {
          // ── Surfaces ──────────────────────────────────────────────────────
          readonly property string crust:   "${colors.crust}"
          readonly property string mantle:  "${colors.mantle}"
          readonly property string base:    "${colors.base}"
          readonly property string surface: "${colors.surface}"
          readonly property string overlay: "${colors.overlay}"
          readonly property string border:  "${colors.border}"

          // ── Text ──────────────────────────────────────────────────────────
          readonly property string text:    "${colors.text}"
          readonly property string subtext: "${colors.subtext}"
          readonly property string muted:   "${colors.muted}"
          readonly property string faint:   "${colors.faint}"

          // ── Accent ────────────────────────────────────────────────────────
          readonly property string accent:  "${colors.accent}"

          // ── Hues ──────────────────────────────────────────────────────────
          readonly property string red:    "${colors.red}"
          readonly property string orange: "${colors.orange}"
          readonly property string yellow: "${colors.yellow}"
          readonly property string green:  "${colors.green}"
          readonly property string teal:   "${colors.teal}"
          readonly property string cyan:   "${colors.cyan}"
          readonly property string blue:   "${colors.blue}"
          readonly property string purple: "${colors.purple}"

          // ── Terminal ANSI (normal) ────────────────────────────────────────
          readonly property string black: "${colors.black}"
          readonly property string white: "${colors.white}"

          // ── Terminal ANSI (bright) ────────────────────────────────────────
          readonly property string brightBlack:  "${colors.brightBlack}"
          readonly property string brightRed:    "${colors.brightRed}"
          readonly property string brightGreen:  "${colors.brightGreen}"
          readonly property string brightYellow: "${colors.brightYellow}"
          readonly property string brightBlue:   "${colors.brightBlue}"
          readonly property string brightPurple: "${colors.brightPurple}"
          readonly property string brightCyan:   "${colors.brightCyan}"
          readonly property string brightWhite:  "${colors.brightWhite}"

          // ── Meta ──────────────────────────────────────────────────────────
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
    };
}
