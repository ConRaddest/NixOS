{ ... }:

{
  flake.lib.homeModules.appearance =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        noto-fonts-cjk-sans
        font-awesome
      ];

      fonts.fontconfig.enable = true;
      dconf.enable = true;

      stylix.targets = {
        gtk.enable = true;
        qt.enable = true;
      };

      # Stylix owns cursor package, name, and size. Keep Hyprcursor integration.
      home.pointerCursor.hyprcursor.enable = true;

      gtk.iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };

      dconf.settings = {
        "org/gnome/desktop/interface".icon-theme = "Adwaita";

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
