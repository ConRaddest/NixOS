{ ... }:

{
  flake.lib.homeModules.theme =
    {
      pkgs,
      font,
      colors,
      ...
    }:

    {
      home.packages = with pkgs; [
        xdg-desktop-portal-gtk
        adwaita-qt
        adwaita-qt6
      ];

      qt = {
        enable = true;
        platformTheme.name = "gtk";
        style = {
          name = "adwaita-dark";
          package = pkgs.adwaita-qt;
        };
      };

      home.pointerCursor = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
        gtk.enable = true;
        hyprcursor.enable = true;
      };

      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        font = {
          name = font.name;
          size = font.size;
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk3.extraCss = ''
          @define-color accent_color          ${colors.blue};
          @define-color accent_bg_color       ${colors.blue};
          @define-color accent_fg_color       ${colors.bg};
          @define-color destructive_color     ${colors.red};
          @define-color destructive_bg_color  ${colors.red};
          @define-color destructive_fg_color  ${colors.bg};
          @define-color success_color         ${colors.green};
          @define-color success_bg_color      ${colors.green};
          @define-color warning_color         ${colors.yellow};
          @define-color warning_bg_color      ${colors.yellow};
          @define-color error_color           ${colors.red};
          @define-color error_bg_color        ${colors.red};
          @define-color window_bg_color       ${colors.bg};
          @define-color window_fg_color       ${colors.fg};
          @define-color view_bg_color         ${colors.bg};
          @define-color view_fg_color         ${colors.fg};
          @define-color headerbar_bg_color    ${colors.bgDark};
          @define-color headerbar_fg_color    ${colors.fg};
          @define-color headerbar_border_color ${colors.bgDark};
          @define-color headerbar_backdrop_color ${colors.bgDark};
          @define-color sidebar_bg_color      ${colors.bgDark};
          @define-color sidebar_fg_color      ${colors.fgDark};
          @define-color sidebar_backdrop_color ${colors.bgDark};
          @define-color sidebar_border_color  ${colors.bgDark};
          @define-color card_bg_color         ${colors.bgDark};
          @define-color card_fg_color         ${colors.fg};
          @define-color popover_bg_color      ${colors.bgDark};
          @define-color popover_fg_color      ${colors.fg};
          @define-color dialog_bg_color       ${colors.bg};
          @define-color dialog_fg_color       ${colors.fg};
          decoration { border-radius: 0; }
          paned > separator { background-image: image(transparent); }
          paned > separator:backdrop { background-image: image(transparent); }
        '';
        gtk4.extraCss = ''
          @define-color accent_color          ${colors.blue};
          @define-color accent_bg_color       ${colors.blue};
          @define-color accent_fg_color       ${colors.bg};
          @define-color destructive_color     ${colors.red};
          @define-color destructive_bg_color  ${colors.red};
          @define-color destructive_fg_color  ${colors.bg};
          @define-color success_color         ${colors.green};
          @define-color success_bg_color      ${colors.green};
          @define-color warning_color         ${colors.yellow};
          @define-color warning_bg_color      ${colors.yellow};
          @define-color error_color           ${colors.red};
          @define-color error_bg_color        ${colors.red};
          @define-color window_bg_color       ${colors.bg};
          @define-color window_fg_color       ${colors.fg};
          @define-color view_bg_color         ${colors.bg};
          @define-color view_fg_color         ${colors.fg};
          @define-color headerbar_bg_color    ${colors.bgDark};
          @define-color headerbar_fg_color    ${colors.fg};
          @define-color headerbar_border_color ${colors.bgDark};
          @define-color headerbar_backdrop_color ${colors.bgDark};
          @define-color sidebar_bg_color      ${colors.bgDark};
          @define-color sidebar_fg_color      ${colors.fgDark};
          @define-color sidebar_backdrop_color ${colors.bgDark};
          @define-color card_bg_color         ${colors.bgDark};
          @define-color card_fg_color         ${colors.fg};
          @define-color popover_bg_color      ${colors.bgDark};
          @define-color popover_fg_color      ${colors.fg};
          @define-color dialog_bg_color       ${colors.bg};
          @define-color dialog_fg_color       ${colors.fg};
        '';
      };

      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "Adwaita";
        font-name = "${font.name} ${toString font.size}";
        document-font-name = "${font.name} ${toString font.size}";
        monospace-font-name = "${font.mono} ${toString font.monoSize}";
      };
    };
}
