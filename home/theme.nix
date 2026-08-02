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

      dconf.enable = true;

      home.pointerCursor = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 22;
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
          name = font.system;
          size = font.size;
        };
        # gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        # gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        # gtk3.extraCss = ''
        #   @define-color accent_color             ${colors.accent};
        #   @define-color accent_bg_color          ${colors.overlay};
        #   @define-color accent_fg_color          ${colors.text};
        #   @define-color destructive_color        ${colors.red};
        #   @define-color destructive_bg_color     ${colors.red};
        #   @define-color destructive_fg_color     ${colors.base};
        #   @define-color success_color            ${colors.green};
        #   @define-color success_bg_color         ${colors.green};
        #   @define-color warning_color            ${colors.yellow};
        #   @define-color warning_bg_color         ${colors.yellow};
        #   @define-color error_color              ${colors.red};
        #   @define-color error_bg_color           ${colors.red};
        #   @define-color window_bg_color          ${colors.base};
        #   @define-color window_fg_color          ${colors.text};
        #   @define-color view_bg_color            ${colors.base};
        #   @define-color view_fg_color            ${colors.text};
        #   @define-color headerbar_bg_color       ${colors.base};
        #   @define-color headerbar_fg_color       ${colors.text};
        #   @define-color headerbar_border_color   ${colors.base};
        #   @define-color headerbar_backdrop_color ${colors.base};
        #   @define-color sidebar_bg_color         ${colors.base};
        #   @define-color sidebar_fg_color         ${colors.text};
        #   @define-color sidebar_backdrop_color   ${colors.base};
        #   @define-color sidebar_border_color     ${colors.base};
        #   @define-color card_bg_color            ${colors.base};
        #   @define-color card_fg_color            ${colors.text};
        #   @define-color popover_bg_color         ${colors.overlay};
        #   @define-color popover_fg_color         ${colors.text};
        #   @define-color dialog_bg_color          ${colors.base};
        #   @define-color dialog_fg_color          ${colors.text};
        # '';
        # gtk4.extraCss = ''
        #   @define-color accent_color             ${colors.accent};
        #   @define-color accent_bg_color          ${colors.overlay};
        #   @define-color accent_fg_color          ${colors.text};
        #   @define-color destructive_color        ${colors.red};
        #   @define-color destructive_bg_color     ${colors.red};
        #   @define-color destructive_fg_color     ${colors.base};
        #   @define-color success_color            ${colors.green};
        #   @define-color success_bg_color         ${colors.green};
        #   @define-color warning_color            ${colors.yellow};
        #   @define-color warning_bg_color         ${colors.yellow};
        #   @define-color error_color              ${colors.red};
        #   @define-color error_bg_color           ${colors.red};
        #   @define-color window_bg_color          ${colors.base};
        #   @define-color window_fg_color          ${colors.text};
        #   @define-color view_bg_color            ${colors.base};
        #   @define-color view_fg_color            ${colors.text};
        #   @define-color headerbar_bg_color       ${colors.base};
        #   @define-color headerbar_fg_color       ${colors.text};
        #   @define-color headerbar_border_color   ${colors.base};
        #   @define-color headerbar_backdrop_color ${colors.base};
        #   @define-color sidebar_bg_color         ${colors.base};
        #   @define-color sidebar_fg_color         ${colors.text};
        #   @define-color sidebar_backdrop_color   ${colors.base};
        #   @define-color card_bg_color            ${colors.base};
        #   @define-color card_fg_color            ${colors.text};
        #   @define-color popover_bg_color         ${colors.base};
        #   @define-color popover_fg_color         ${colors.text};
        #   @define-color dialog_bg_color          ${colors.base};
        #   @define-color dialog_fg_color          ${colors.text};
        # '';
      };

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "adw-gtk3-dark";
          icon-theme = "Adwaita";
          font-name = "${font.system} ${toString font.size}";
          document-font-name = "${font.system} ${toString font.size}";
          monospace-font-name = "${font.mono} ${toString font.monoSize}";
        };

        "org/gnome/nautilus/preferences" = {
          default-sort-order = "name";
          default-sort-in-reverse-order = false;
        };

        "org/gtk/gtk4/settings/file-chooser" = {
          sort-column = "name";
          sort-order = "ascending";
          sort-directories-first = true;
        };

        "org/gtk/settings/file-chooser" = {
          sort-column = "name";
          sort-order = "ascending";
          sort-directories-first = true;
        };
      };
    };
}
