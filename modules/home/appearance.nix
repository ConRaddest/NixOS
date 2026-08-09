{ ... }:

{
  flake.lib.homeModules.appearance =
    {
      pkgs,
      font,
      ...
    }:

    {
      home.packages = with pkgs; [
        adw-gtk3
        kdePackages.qt6ct

        adwaita-fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        nerd-fonts.jetbrains-mono
        font-awesome
      ];

      fonts.fontconfig.enable = true;

      # Writable qt6ct/GTK color files are intentionally left to desktop-shell
      # theming. Nix only supplies stable baseline fonts, icons, cursor, style.
      home.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
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
